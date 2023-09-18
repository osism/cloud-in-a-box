# Cloud in a Box

Cloud in a Box is a minimalistic installation of OSISM with only services which are
needed to make it run.

For informations how to install the Cloud in a Box, please have a look at the
[Cloud in a Box Guide](https://osism.github.io/docs/advanced-guides/cloud-in-a-box).

## Types

There are two types of Cloud in a Box.

The sandbox type is intended for developers and demonstrations. A full OSISM installation
is one there which also includes Ceph and OpenSearch, for example. In the course of the
installation, necessary images, networks, etc. are also created.

The edge type is intended to be deployed as an appliance to provide an edge cloud on a
single node. Compared to the sandbox, certain services are not provided there or are
implemented differently. For example, OpenSearch is not deployed because the logs are
delivered to a central location. The storage backend will also be implemented differently there
in the future instead of Ceph.
