# sshd

**WARNING:** The SSH jumppod does right now not allow host-key specification.
As a consequence the host key checks in the examples below are disabled.
Therefore it is right now only recommended to use this repo in combination with
`kubectl port-forward` and not via `LoadBalancer` or `NodePort` service.

Deploy the service with an example `authorized_keys` file:

```bash
$ kubectl create configmap authorized-keys --from-file=example/authorized_keys
$ kubectl create -f manifests/deployment.yaml
```

Using `port-forward` to open a connection to your local machine:

```bash
kubectl port-forward svc/sshd 2222:22 &
```

Connect to the ssh server:

```bash
ssh -o StrictHostKeyChecking=no localhost -p 2222 -i example/vagrant.key
```

With the port-forward established, we can define a jumphost in our `.ssh/config` file:

```
Host jumphost
   HostName localhost
   User nonroot
   Port 2222
   IdentityFile ~/ssh-jumphost/example/vagrant
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
```

Define a headless service to assign nice uniqe DNS names to every VMI in a cluster:

```bash
kubectl create -f example/vmis.yaml
```

We now have defined a headless service which will create unique DNS entries for
each of the two small Cirros VMs.

Once they are up, we can connect like this to them (password is `gocubsgo`):

```bash
ssh -o StrictHostKeyChecking=no cirros@cirros0.ansiblemachines -J jumphost
ssh -o StrictHostKeyChecking=no cirros@cirros1.ansiblemachines -J jumphost
```

We can also define entries in `.ssh/config`:

```
Host cirros0.ansiblemachines
   HostName cirros0.ansiblemachines
   User cirros
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
   ProxyJump jumphost
Host cirros1.ansiblemachines
   HostName cirros0.ansiblemachines
   User cirros
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
   ProxyJump jumphost
```
