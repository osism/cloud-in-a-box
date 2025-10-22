# CA for testbed

Inspired by (i.e. mostly stolen from)
https://docs.ansible.com/ansible/latest/collections/community/crypto/docsite/guide_ownca.html

## Usage

Create a CA certificate and key:

```
ansible-playbook create-ca.yml
```

Create a wildcard certificate:

```
ansible-playbook create-wildcard.yml
```

Install the new certificates into the environment:

```
ansible-playbook install-certificates.yml
```

## TODO

* Document changing the certificate for traefik after it is moved into a file.
