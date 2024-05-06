venv = . venv/bin/activate
export PATH := ${PATH}:${PWD}/venv/bin

deps: venv/bin/activate ## Install software preconditions to `venv`.

prune:
	rm -rf venv

venv/bin/activate: Makefile requirements.txt
	@which python3 > /dev/null || { echo "Missing requirement: python3" >&2; exit 1; }
	@[ -e venv/bin/python ] || python3 -m venv venv --prompt osism-$(shell basename ${PWD})
	@${venv} && pip3 install -r requirements.txt
	touch venv/bin/activate

sync: deps
	@[ "${BRANCH}" ] && sed -i -e "s/version: .*/version: ${BRANCH}/" gilt.yml || exit 0
	@${venv} && gilt overlay && gilt overlay

ansible_vault_rekey: deps
	pwgen -1 32 > secrets/vaultpass.new
	${venv} && find environments/ inventory/ -name "*.yml" -exec grep -l ANSIBLE_VAULT {} \+|\
		sort -u|\
		xargs -n 1 --verbose ansible-vault rekey  -v \
		--vault-password-file secrets/vaultpass \
		--new-vault-password-file secrets/vaultpass.new
	mv secrets/vaultpass.new secrets/vaultpass

ansible_vault_show: deps
	${venv} && find environments/ inventory/ -name "*.yml" -exec grep -l ANSIBLE_VAULT {} \+|\
		sort -u|\
		xargs -n 1 --verbose ansible-vault view --vault-password-file secrets/vaultpass | cat

phony: deps prune sync ansible_vault_rekey ansible_vault_show
