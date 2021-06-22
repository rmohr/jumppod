# jumppod

## What does this do?

Suppose you have ansible and you want to provision KubeVirt VMs in a kubernets
cluster, jumppod can help you reaching all VMs in your inventory easily by
kubernetes assigned DNS names by e.g. headless services.

The jumppod is a small sshd deployement for k8s. It can be easily deployed and
can be exposed via `kubectl port-forward`, `LoadBalancer` or `NodePort`
services.

Once running and exposed, you have a jump pod inside your kubernetes cluster
with KubeVirt, including kube-dns resolution.

Ensure that your VMIs which you want to access are part of a headless service
(https://kubevirt.io/user-guide/virtual_machines/dns/#dns-records) and you will
have nice DNS names for your VMs for ansible or yourself without the need for a
ton of `ClusterIP` services or plain IPs just for administrational tasks.

## Security considerations

jumppod should be pretty safe to use:
 * The sshd servers in the jumppod deployment run in unprivileged pods.
 * The host-keys are provided via a secret and not regenerated to prevent MITM (so that you trust the host key signature and do not disable the checks).

## Deploy jumppod

### Publish host-keys for sshd as a secret and create the deployment

```bash
mkdir -p ~/etc/ssh && ssh-keygen -A -f ~/
kubectl create secret generic host-keys --from-file=${HOME}/etc/ssh
rm -rf ~/etc/ssh
kubectl create -f https://raw.githubusercontent.com/rmohr/jumppod/main/manifests/deployment.yaml
```

### Manage access

Access can be given or revoked by updating a `configmap` called
`authorized-keys` which contains a `authorized_keys` file.

It is easy to transform an existing `authorized_keys` file or your `id_rsa.pub`
file into the required configmap:

```bash
kubectl create configmap authorized-keys --from-file=authorized_keys=${HOME}/.ssh/id_rsa.pub
```

### Exposing the service via a NodePort

Create a nodeport service which will expose sshd on port
`32222`:

```bash
kubectl create service nodeport sshd-nodeport --node-port 32222 --tcp 2222:2222
```

Define an entry like this in `.ssh/config`

```
Host jumphost
   HostName <node-ip>
   User nonroot
   Port 32222
```

### Exposing the service via kubectl port-forward

Using `port-forward` to open a connection to your local machine:

```bash
kubectl port-forward svc/sshd 2222:22 &
```

Connect to the ssh server:

```bash
ssh nonroot@localhost -p 2222
```

With the port-forward established, we can define a jumphost in our `.ssh/config` file:

```
Host jumphost
   HostName localhost
   User nonroot
   Port 2222
```

### Define a headless service to assign nice uniqe DNS names to every VMI in a cluster

We now have defined a headless service which will create unique DNS entries for
each of the two small Cirros VMs.

```bash
kubectl create -f example/vmis.yaml
```

Once they are up, we can connect like this to them (password is `gocubsgo`):

```bash
ssh cirros@cirros0.ansiblemachines -J jumphost
ssh cirros@cirros1.ansiblemachines -J jumphost
```

We can also define entries in `.ssh/config` which will use the jumphost automatically:

```
Host cirros0.ansiblemachines
   HostName cirros0.ansiblemachines
   User cirros
   ProxyJump jumphost
Host cirros1.ansiblemachines
   HostName cirros1.ansiblemachines
   User cirros
   ProxyJump jumphost
```
