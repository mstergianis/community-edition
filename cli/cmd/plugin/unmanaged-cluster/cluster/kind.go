// Copyright 2021 VMware Tanzu Community Edition contributors. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package cluster

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"regexp"
	"strings"

	"gopkg.in/yaml.v3"
	kindconfig "sigs.k8s.io/kind/pkg/apis/config/v1alpha4"
	kindcluster "sigs.k8s.io/kind/pkg/cluster"
	"sigs.k8s.io/kind/pkg/exec"

	"github.com/vmware-tanzu/community-edition/cli/cmd/plugin/unmanaged-cluster/config"
)

const minMemoryBytes = 2147483648
const minCPUCount = 1

// TODO(stmcginnis): Keeping this here for now for reference, remove once we're
// ready with custom configurations.
// const defaultKindConfig = `kind: Cluster
// apiVersion: kind.x-k8s.io/v1alpha4
// nodes:
// - role: control-plane
//   #! port forward 80 on the host to 80 on this node
//   extraPortMappings:
//   - containerPort: 80
//     #!hostPort: 80
//     #! optional: set the bind address on the host
//     #! 0.0.0.0 is the current default
//     listenAddress: "127.0.0.1"
//     #! optional: set the protocol to one of TCP, UDP, SCTP.
//     #! TCP is the default
//     protocol: TCP
// networking:
//   disableDefaultCNI: true`

// KindClusterManager is a ClusterManager implementation for working with
// Kind clusters.
type KindClusterManager struct {
}

// Create will create a new kind cluster or return an error.
func (kcm KindClusterManager) Create(c *config.UnmanagedClusterConfig) (*KubernetesCluster, error) {
	kindProvider := kindcluster.NewProvider()
	clusterConfig := kindcluster.CreateWithKubeconfigPath(c.KubeconfigPath)

	// TODO(stmcginnis): Determine what we need to do for kind configuration
	parsedKindConfig, err := kindConfigFromClusterConfig(c)
	if err != nil {
		return nil, err
	}
	kindConfig := kindcluster.CreateWithRawConfig(parsedKindConfig)
	err = kindProvider.Create(c.ClusterName, clusterConfig, kindConfig)
	if err != nil {
		return nil, err
	}

	// readkubeconfig in bytes
	kcBytes, err := os.ReadFile(c.KubeconfigPath)
	if err != nil {
		return nil, err
	}

	kc := &KubernetesCluster{
		Name:       c.ClusterName,
		Kubeconfig: kcBytes,
	}

	if strings.Contains(c.Cni, "antrea") {
		nodes, _ := kindProvider.ListNodes(c.ClusterName)
		for _, n := range nodes {
			if err := patchForAntrea(n.String()); err != nil { //nolint:staticcheck
				// TODO(stmcginnis): We probably don't want to just error out
				// since the cluster has already been created, but we should
				// at least report a warning back to the user that part of the
				// setup failed.
			}
		}
	}

	return kc, nil
}

func kindConfigFromClusterConfig(c *config.UnmanagedClusterConfig) ([]byte, error) {
	// Load the defaults
	kindConfig := &kindconfig.Cluster{}
	kindConfig.Kind = "Cluster"
	kindConfig.APIVersion = "kind.x-k8s.io/v1alpha4"
	kindConfig.Name = c.ClusterName
	kindconfig.SetDefaultsCluster(kindConfig)

	// Now populate or override with the specified configuration
	kindConfig.Networking.DisableDefaultCNI = true
	if c.PodCidr != "" {
		kindConfig.Networking.PodSubnet = c.PodCidr
	}
	if c.ServiceCidr != "" {
		kindConfig.Networking.ServiceSubnet = c.ServiceCidr
	}
	for i := range kindConfig.Nodes {
		kindConfig.Nodes[i].Image = c.NodeImage

		// We do the port mapping for all nodes. Need to see if there is a way
		// to change this if we support scaling worker nodes.
		for j := range c.PortsToForward {
			portMapping := kindconfig.PortMapping{}
			if c.PortsToForward[j].ContainerPort != 0 {
				portMapping.ContainerPort = int32(c.PortsToForward[j].ContainerPort)
			}
			if c.PortsToForward[j].HostPort != 0 {
				portMapping.HostPort = int32(c.PortsToForward[j].HostPort)
			}
			if c.PortsToForward[j].Protocol != "" {
				portMapping.Protocol = kindconfig.PortMappingProtocol(c.PortsToForward[j].Protocol)
			}

			kindConfig.Nodes[i].ExtraPortMappings = append(kindConfig.Nodes[i].ExtraPortMappings, portMapping)
		}
	}

	// Marshal it into the raw bytes we need for creation
	var rawConfig bytes.Buffer
	yamlEncoder := yaml.NewEncoder(&rawConfig)

	err := yamlEncoder.Encode(kindConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to generate Kind configuration. Error: %s", err.Error())
	}
	err = yamlEncoder.Close()
	if err != nil {
		return nil, fmt.Errorf("failed to generate Kind configuration. Error: %s", err.Error())
	}

	return rawConfig.Bytes(), nil
}

// Get retrieves cluster information or return an error indicating a problem.
func (kcm KindClusterManager) Get(clusterName string) (*KubernetesCluster, error) {
	return nil, nil
}

// Delete removes a kind cluster.
func (kcm KindClusterManager) Delete(c *config.UnmanagedClusterConfig) error {
	provider := kindcluster.NewProvider()
	return provider.Delete(c.ClusterName, "")
}

// Prepare will fetch a container image to the cluster host.
func (kcm KindClusterManager) Prepare(c *config.UnmanagedClusterConfig) error {
	cmd := exec.Command("docker", "pull", c.NodeImage)
	_, err := exec.Output(cmd)
	if err != nil {
		return err
	}
	return nil
}

// PreflightCheck performs any pre-checks that can find issues up front that
// would cause problems for cluster creation.
func (kcm KindClusterManager) PreflightCheck() []error {
	// Check presence of docker
	cmd := exec.Command("docker", "ps")
	if err := cmd.Run(); err != nil {
		// In this case we can't check the rest of the settings, so just return
		// the one error.
		return []error{
			fmt.Errorf("docker is not installed or not reachable. Verify it's installed, running, and your user has permissions to interact with it. Error when attempting to run docker ps: %w", err)}
	}

	// Get Docker info
	cmd = exec.Command("docker", "info", "--format", "{{ json . }}")
	output, err := exec.Output(cmd)
	if err != nil {
		return []error{fmt.Errorf("unable to get docker info: %w", err)}
	}

	if issues := validateDockerInfo(output); len(issues) != 0 {
		return issues
	}

	return nil
}

type dockerInfo struct {
	CPUs         int    `json:"NCPU"`
	Memory       int64  `json:"MemTotal"`
	Architecture string `json:"Architecture"`
}

func validateDockerInfo(output []byte) []error {
	info := dockerInfo{}
	if err := json.Unmarshal(output, &info); err != nil {
		// Nothing else we can check, just return this error right away
		return []error{errors.New("unable to parse Docker information")}
	}

	issues := []error{}

	if !strings.HasSuffix(info.Architecture, "x86_64") {
		// Only amd64 supported right now, no arm
		issues = append(issues, errors.New("only amd64 architecture currently supported"))
	}

	if info.CPUs < minCPUCount {
		// Should only hit this if there is an issue getting the docker info
		// correctly, but we can also raise this if we find the need
		issues = append(issues, fmt.Errorf("minimum %d CPU core is required", minCPUCount))
	}

	if info.Memory < minMemoryBytes {
		issues = append(issues, fmt.Errorf("minimum %d GiB of memory is required", (minMemoryBytes/1024/1024/1024)))
	}

	return issues
}

// patchForAntrea modifies the node network settings to allow local routing.
// this needs to happen for antrea running on kind or else you'll lose network connectivity
// see: https://github.com/antrea-io/antrea/blob/main/hack/kind-fix-networking.sh
func patchForAntrea(nodeName string) error {
	// First need to get the ID of the interface from the cluster node.
	cmd := exec.Command("docker", "exec", nodeName, "ip", "link")
	out, err := exec.Output(cmd)
	if err != nil {
		return err
	}
	re := regexp.MustCompile("eth0@if(.*?):")
	match := re.FindStringSubmatch(string(out))
	peerIdx := match[1]

	// Now that we have the ID, we need to look on the host network to find its name.
	cmd = exec.Command("docker", "run", "--rm", "--net=host", "antrea/ethtool:latest", "ip", "link")
	outLines, err := exec.OutputLines(cmd)
	if err != nil {
		return err
	}
	peerName := ""
	re = regexp.MustCompile(fmt.Sprintf("^%s: (.*?)@.*:", peerIdx))
	for _, line := range outLines {
		match = re.FindStringSubmatch(line)
		if len(match) > 0 {
			peerName = match[1]
			break
		}
	}

	if peerName == "" {
		return fmt.Errorf("unable to find node interface %q on host network", peerIdx)
	}

	// With the name, we can now use ethtool to turn off TX checksumming offload
	cmd = exec.Command("docker", "run", "--rm", "--net=host", "--privileged", "antrea/ethtool:latest", "ethtool", "-K", peerName, "tx", "off")
	_, err = exec.Output(cmd)
	if err != nil {
		return err
	}

	// Finally, enable local routing
	cmd = exec.Command("docker", "exec", nodeName, "sysctl", "-w", "net.ipv4.conf.all.route_localnet=1")
	_, err = exec.Output(cmd)
	if err != nil {
		return err
	}

	return nil
}
