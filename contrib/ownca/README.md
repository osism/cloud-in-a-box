# CA for testbed

Inspired by (i.e. mostly stolen from)
https://docs.ansible.com/ansible/latest/collections/community/crypto/docsite/guide_ownca.html

## Usage

Create a CA certificate and key:

```
ansible-playbook create_ca.yml
```

Create a wildcard certificate:

```
ansible-playbook create_wildcard.yml
```

Create a manager certificate (optional, can also use wildcard cert):

```
ansible-playbook create_manager.yml
```

Install the new certificates into the environment:

```
$ cp contrib/ownca/cloud-in-a-box-ca-certificate.pem environments/kolla/certificates/ca/cloud-in-a-box.crt
$ cp contrib/ownca/cloud-in-a-box-ca-certificate.pem environments/openstack/cloud-in-a-box.pem
$ cat contrib/ownca/cloud-in-a-box-{certificate.key,certificate.pem,ca-certificate.pem} > environments/kolla/certificates/haproxy.pem
$ ansible-vault encrypt --vault-pass-file environments/.vault_pass environments/kolla/certificates/haproxy.pem
$ cp environments/kolla/certificates/haproxy.pem environments/kolla/certificates/haproxy-internal.pem
```

## TODO

* Document changing the certificate for traefik after it is moved into a file.
* Write a playbook for the installation step.
