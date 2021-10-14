# Camel K selective upgrade demo

This demo shows how two Camel K operators can be set to run in parallel and reconcile their own integrations,
making it possible to selectively upgrade and downgrade individual integrations across the cluster.

# Setup

This is a POC and runs on Minikube. It requires Camel K 1.7.0 (unreleased at the time of writing this demo)
or Camel K 1.7.0-SNAPSHOT compiled from the `release-1.7.x` (or `main` until release) branch.

Using:
- `kamel` Camel K CLI (see above for version version)
- `kubectl` tool
- `stern` tool to display the logs (or similar)

## 1. Prepare the cluster

The simplest way to prepare roles and service accounts for the two operators is to install Camel K using the CLI:

```
kamel install --global -n default -w --force
```

We don't need the default operator, so we remove the deployment and platform related resources:

```
kubectl delete deployment camel-k-operator
kubectl delete ip --all
kubectl delete cm camel-k-maven-settings || true
```

Now we can install the two operators.

NOTE: you **must** edit the `setup/platform-*` resources to set your own ip address of the Minikube registry. You need also set the proper operator image if you're not using a SNAPSHOT.

After doing the changes, to install the two operators:

```
kubectl apply -f setup/
```

You should see two operators in the `default` namespace and both integration platforms should be quickly reconciled.

## 2. Run the connectors

Create a `user` namespace and switch to it:

```
kubectl create ns user
kubectl config set-context --current --namespace user
```

Now we can create two connectors associated to the first operator:

```
kubectl apply -f my-connector-1.yaml
kubectl apply -f my-connector-2.yaml
```

When `kubectl get klb` returns that they are `Running`, it means that the first operator reconciled both of them, while the second is idle (and printing messages indicating that it's ignoring those resources).

## 3. Watching the two connectors

The two connectors just print messages to the logs. To distinguish the version of the operator they are running with, you can notice:

- The `v1` operator/platform will materialize integrations that don't use colors in the logs
- The `v2` operator/platform will materialize integrations that do use colors in the logs

You can see the logs using (in another terminal):

```
stern my-connector
```

Both integrations will have uncolored logs.

## 4. Upgrading integrations

The script `upgrade.sh` can be used to upgrade an integration to `v2`, while `downgrade.sh` will downgrade it to `v1`.
Upgrading and downgrading mean passing the integration management responsibility from one operator to the other.

You can play with the connectors:

```
./upgrade.sh my-connector-1
sleep 30
./upgrade.sh my-connector-2
sleep 30
./downgrade.sh my-connector-1
./downgrade.sh my-connector-2
```

What's inside the upgrade and downgrade scripts can be automated in a "supervisor" operator.
