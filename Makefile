venv = . venv/bin/activate
export PATH := ${PATH}:${PWD}/venv/bin

VAULTPASS_FILE ?= ${PWD}/secrets/vaultpass

ifeq (,$(wildcard ${VAULTPASS_FILE}))
    ifneq (,$(shell docker ps --filter 'name=osism-ansible' --format '{{.Names}}' 2>/dev/null))
        VAULTPASS_FILE := ${PWD}/secrets/vaultpass-wrapper.sh
        $(shell echo "#!/usr/bin/env bash" > ${VAULTPASS_FILE})
        $(shell echo "docker exec osism-ansible /ansible-vault.py" >> ${VAULTPASS_FILE})
    else
        $(shell echo "INFO: the file VAULTPASS_FILE='${VAULTPASS_FILE}' does not exist and no running 'osism-ansible' container" >&2)
    endif
else
    $(shell echo "INFO: ${VAULTPASS_FILE} exists, using the vault password defined in the file" >&2)
endif


.PHONY: deps
deps: venv/bin/activate ## Install software preconditions to `venv`.

.PHONY: prune
prune:
	rm -rf venv

venv/bin/activate: Makefile requirements.txt
	@which python3 > /dev/null || { echo "Missing requirement: python3" >&2; exit 1; }
	@[ -e venv/bin/python ] || python3 -m venv venv --prompt osism-$(shell basename ${PWD})
	@${venv} && pip3 install -r requirements.txt
	touch venv/bin/activate

.PHONY: deps
sync: deps
	@[ "${BRANCH}" ] && sed -i -e "s/version: .*/version: ${BRANCH}/" gilt.yml || exit 0
	@${venv} && gilt overlay && gilt overlay

.PHONY: check_vault_pass
check_vault_pass:
	@test -r "${VAULTPASS_FILE}"  || ( echo "the file VAULTPASS_FILE='${VAULTPASS_FILE}' does not exist"; exit 1)

.PHONY: ansible_vault_encrypt_ceph_keys
ansible_vault_encrypt_ceph_keys: deps check_vault_pass
	 @${venv} ; find . -name "ceph.client.*.keyring"|while read FILE; do \
	 echo "-> $${FILE}"; \
	 if ! ( grep -q "^.ANSIBLE_VAULT" $${FILE} );then \
		ansible-vault encrypt $${FILE} --output $${FILE}.vaulted --vault-password-file ${VAULTPASS_FILE} && \
		mv $${FILE}.vaulted $${FILE}; \
	 fi \
	done

.PHONY: ansible_vault_decrypt_ceph_keys
ansible_vault_decrypt_ceph_keys: deps check_vault_pass
	 @${venv} ; find . -name "ceph.client.*.keyring"|while read FILE; do \
	 echo "-> $${FILE}"; \
	 if ( grep -q "^.ANSIBLE_VAULT" $${FILE} );then \
		ansible-vault decrypt $${FILE} --output $${FILE}.unvaulted --vault-password-file ${VAULTPASS_FILE} && \
		mv $${FILE}.unvaulted $${FILE}; \
	 fi \
	done


.PHONY: ansible_vault_rekey
ansible_vault_rekey: deps check_vault_pass
	@echo "${VAULTPASS_FILE}" |grep -q -v ".sh$$" || ( echo "WARNING: the file VAULTPASS_FILE='${VAULTPASS_FILE}' is not a password file, exitting here"; exit 1)
	@if ! git diff-index --quiet HEAD --; then \
	    echo "Error: Uncommitted changes found in the repository. Stash or drop them before rekeying."; \
            git diff; \
	    exit 1; \
	fi
	openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 32  > ${VAULTPASS_FILE}.new
	@echo "INFO: creating a backup"
	cp ${VAULTPASS_FILE} ${VAULTPASS_FILE}_backup_$(shell date --date="today" "+%Y-%m-%d_%H-%M-%S"); \
	@echo "INFO: perform rekeying"
	${venv} && find environments/ inventory/ -name "*.yml" -not -path "*/.venv/*" -exec grep -l '^.ANSIBLE_VAULT' {} \+|\
		sort -u|\
		xargs -n 1 --verbose ansible-vault rekey  -v \
		--vault-password-file ${VAULTPASS_FILE} \
		--new-vault-password-file ${VAULTPASS_FILE}.new
	@echo "INFO: move new key in place"
	mv ${VAULTPASS_FILE}.new ${VAULTPASS_FILE}

.PHONY: ansible_vault_show
ansible_vault_show: deps check_vault_pass
ifndef FILE
	$(error FILE variable is not set, example 'make ansible_vault_edit FILE=environments/secrets.yml' or 'make ansible_vault_show FILE=all')
endif
	@if [ "${FILE}" = "all" ] ; then \
		${venv} && find environments/ inventory/ -name "*.yml" -and -not -path "*/.venv/*" -exec grep -l '^.ANSIBLE_VAULT' {} \+|\
			sort -u|\
			xargs -n 1 --verbose ansible-vault view --vault-password-file ${VAULTPASS_FILE} 2>&1 | less;\
	else \
		${venv} ; ansible-vault view --vault-password-file ${VAULTPASS_FILE} ${FILE}; \
	fi


.PHONY: ansible_vault_edit
ansible_vault_edit: deps check_vault_pass
ifndef FILE
	$(error FILE variable is not set, example 'make ansible_vault_edit FILE=environments/secrets.yml')
endif
	@if ( test -f $(FILE) && grep -q ANSIBLE_VAULT $(FILE) ); then \
		${venv} && ansible-vault edit --vault-password-file ${VAULTPASS_FILE} ${FILE}; \
	elif test -f $(FILE) ; then \
		${venv} && ansible-vault encrypt --vault-password-file ${VAULTPASS_FILE} ${FILE}; \
	else \
		${venv} && ansible-vault create --vault-password-file ${VAULTPASS_FILE} ${FILE}; \
	fi


.PHONY: ansible_vault_encrypt_string
ansible_vault_encrypt_string: deps check_vault_pass
		@${venv} && ansible-vault encrypt_string --vault-password-file ${VAULTPASS_FILE}
