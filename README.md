# Cloud in a Box

Cloud in a Box is a minimalistic installation of OSISM with only services which are
needed to make it run.

With the Cloud in a Box, it is possible to run a full [Sovereign Cloud Stack](https://scs.community)
deployment.

For information how to install the Cloud in a Box, please have a look at the
[Cloud in a Box Guide](https://osism.tech/docs/guides/other-guides/cloud-in-a-box).

The development notes in the official documentation are useful for
[bug fixes and the further development](https://osism.tech/docs/guides/other-guides/cloud-in-a-box/#development) of CiaB.

## Types

There are three types of Cloud in a Box.

1. The `sandbox` type is intended for developers and demonstrations. A full OSISM installation
   is one there which also includes Ceph and OpenSearch, for example. In the course of the
   installation, necessary images, networks, etc. are also created.

2. The `edge` type is intended to be deployed as an appliance to provide an edge cloud on a
   single node. Compared to the sandbox, certain services are not provided there or are
   implemented differently. For example, OpenSearch is not deployed because the logs are
   delivered to a central location. The storage backend will also be implemented differently
   there in the future instead of Ceph.

3. The `kubernetes` type is intended to be deployed as an appliance to provide a edge Kubernetes
   cluster on a single node.
