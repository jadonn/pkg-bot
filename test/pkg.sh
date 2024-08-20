setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'
}

function add_uca_repo() {
	add-apt-repository ppa:ubuntu-cloud-archive/tools --yes
}

function install_dependencies() {
	apt install ubuntu-dev-tools \
		sbuild \
		git-buildpackage \
		cloud-archive-utils \
		openstack-pkg-tools \
		dh-python \
		sphinx-common \
		python3-pbr \
		debhelper \
		sendmail\
		-y
}

function setup_sbuild() {
	mk-sbuild "$TARGET_RELEASE"
}

function add_ssh_key() {
	echo "$SSH_KEY" > /root/.ssh/id_rsa
}

function clone_repo() {
	git clone git+ssh://"$LP_USERNAME"@git.launchpad.net/~ubuntu-openstack-dev/ubuntu/+source/"$PROJECT_NAME" ./
}

function checkout_branches() {
	git checkout --track origin/pristine-tar
	git checkout --track origin/upstream
	git checkout master
}

function merge_upstream() {
	git merge -Xtheirs $(git describe --tag upstream) -m "New upstream snapshot"
}

function add_debian_changelog_entry() {
	dch -v "$(git describe --tag upstream)-0ubuntu1" "New upstream snapshot"
}

function refresh_patches() {
	while (quilt push); do quilt refresh; done
	quilt pop -a
}

function build_source_package() {
	gbp buildpackage -S -d
}

function build_binary_package() {
	sbuild -A -d "$TARGET_RELEASE"_"$TARGET_ARCHITECTURE" "../build-area/$PROJECT_NAME_$(git describe --tag upstream)-0ubuntu1.dsc"
}

@test "Add the Ubuntu Cloud Archive repo" {
	run add_uca_repo
	assert_output --partial "Reading package lists... Done"
}

@test "Install dependencies" {
	run install_dependencies
	assert_output --regexp "[0-9]* upgraded, [0-9]* newly installed, [0-9]* to remove and [0-9]* not upgraded."
}

@test "Setup sbuild" {
	run setup_sbuild

	refute_output 'You must be a member of the 'sbuild' group.'
}

@test "Add SSH key" {
	run add_ssh_key
}

@test "Clone the repo" {
	run clone_repo
}

@test "Checkout branches" {
	run checkout_branches
}

@test "Merge upstream changes" {
	run merge_upstream
}

@test "Update Debian changelog" {
	run add_debian_changelog_entry
}

@test "Refresh Debian patches" {
	run refresh_patches
}

@test "Test the build source package" {
	run build_source_package
}

@test "Test binary build" {
	run build_binary_package
}