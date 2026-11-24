# AAP Enablement Series - Using OpenSCAP

Demo of running OpenSCAP tool against target system to generate report of vulnerabilties

TODO:

- Run `ansible-navigator` to test against target Vagrant machine or just container?
- Create AAP job template with survey to demo this
- Email HTML report to myself
- Push HTML reports to git repo? organized with inventory_hostname?
- Move `build.yml` to my EE (to build latest version)
- Update meta info
- Perhaps create HTML template (jinja template) to push inside OpenSCAP tool so it leverages different colors or style?

## Links

- Training Docker OpenSCAP
  https://github.com/PThierry/openscap_training_docker
- Security Compliance with Ansible and OpenSCAP
  https://www.virtualnebula.com/blog/2021/11/12/security-compliance-with-ansible-and-openscap
  https://www.virtualnebula.com/blog/2021/11/12/security-compliance-with-ansible-and-openscap-part-2

## Details

- Commands
  - List profiles `oscap info "/usr/share/xml/scap/ssg/content/ssg-rhel6-xccdf.xml"`

- OpenSCAP Base
  - Package `openscap-scanner`
    https://www.open-scap.org/tools/openscap-base/

    ```shell
    dnf -y install openscap-scanner
    ```

- OpenSCAP content
  - exists in the `scap-security-guide` package which is not available within UBI images
    https://github.com/ComplianceAsCode/content/issues/9759
  - Spoke with Gabriel Becker from Red Hat about this issue
  - Start docker image `docker run -it --name test registry.access.redhat.com/ubi9/ubi:latest bash`
    Install package `dnf install scap-security-guide` results with "No match for argument: scap-security-guide"
  - Have to install latest release from upstream project

    ```shell
    mkdir oscap
    cd oscap
    wget `curl -s https://api.github.com/repos/ComplianceAsCode/content/releases/latest | jq -r '.assets[4].browser_download_url'`
    unzip scap-security-guide-*.zip
    ```

- Workshop http://redhatgov.io/workshops/ansible_automation/exercise3.0/
  Use OpenSCAP to read a hardening profile via Extensible Configuration Checklist Description Format (XCCDF) and generate an Ansible remediation playbook.
`sudo -u awx oscap xccdf generate fix --fix-type ansible --profile xccdf_org.ssgproject.content_profile_ospp --output ospp-rhel8.yml --fetch-remote-resources /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml`
