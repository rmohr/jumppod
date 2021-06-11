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
(https://kubevirt.io/user-guide/virtual_machines/dns/#dns-records).

## Deploy jumppod

### Publish host-keys for sshd as a secret and create the deployment

```bash
mkdir -p ~/etc/ssh && ssh-keygen -A -f ~/
kubectl create secret generic host-keys --from-file=${HOME}/etc/ssh
rm -rf ~/etc/ssh
kubectl create -f manifests/deployment.yaml
```

### Manage access

Access can be given or revoked by updating a `configmap` called
`authorized-keys` which contains a `authorized_keys` file.

It is easy to transform an existing `authorized_keys` file into the required
configmap:

```bash
kubectl create configmap authorized-keys --from-file=example/authorized_keys
```

### Exposing the service via kubectl port-forward

Using `port-forward` to open a connection to your local machine:

```bash
kubectl port-forward svc/sshd 2222:22 &
```

Connect to the ssh server:

```bash
ssh nonroot@localhost -p 2222 -i example/vagrant.key
```

With the port-forward established, we can define a jumphost in our `.ssh/config` file:

```
Host jumphost
   HostName localhost
   User nonroot
   Port 2222
   IdentityFile ~/ssh-jumphost/example/vagrant
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
