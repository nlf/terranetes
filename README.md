## terranetes

This project is designed to run a single node-type (as in, each node runs both master and worker components) kubernetes cluster on [packet](https://packet.net).

### variables

Any variables without defaults *must* be specified, the easiest way is to create a `terraform.tfvars` file.

- `packet_project_id`: the uuid of the packet project you'd like to create the cluster in
- `packet_token`: your packet.net api token
- `master_name`: the dns name you'd like to use to access your cluster (default: `master`)
- `domain`: the root domain for your cluster (i.e. example.com)
- `private_key_path`: path to the private key file to authenticate to your servers with
- `node_count`: how many nodes to create (should probably be an odd number, default: `3`)
- `node_plan`: the node plan to use (default: `baremetal_0`)
- `node_facility`: the facility to create the nodes in (defualt: `ewr1`)
