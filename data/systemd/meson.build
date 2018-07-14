systemd = dependency('systemd')
systemdsystemunitdir = systemd.get_pkgconfig_variable('systemdsystemunitdir')
bindir = join_paths(get_option('prefix'), get_option('libexecdir'), 'shopsystem')

cfg = configuration_data()
cfg.set('PATH', bindir)

install_data('shopsystem-mail-daily-invoice.timer', install_dir: systemdsystemunitdir)
install_data('shopsystem-mail-monthly-invoice.timer', install_dir: systemdsystemunitdir)
install_data('shopsystem-mail-backup.timer', install_dir: systemdsystemunitdir)

configure_file(input: 'shopsystem-input-device.service.in', output: 'shopsystem-input-device.service', configuration: cfg, install_dir: systemdsystemunitdir)
configure_file(input: 'shopsystem-mail-backup.service.in', output: 'shopsystem-mail-backup.service', configuration: cfg, install_dir: systemdsystemunitdir)
configure_file(input: 'shopsystem-mail-daily-invoice.service.in', output: 'shopsystem-mail-daily-invoice.service', configuration: cfg, install_dir: systemdsystemunitdir)
configure_file(input: 'shopsystem-mail-monthly-invoice.service.in', output: 'shopsystem-mail-monthly-invoice.service', configuration: cfg, install_dir: systemdsystemunitdir)
configure_file(input: 'shopsystem-ui.service.in', output: 'shopsystem-ui.service', configuration: cfg, install_dir: systemdsystemunitdir)
configure_file(input: 'shopsystem-web.service.in', output: 'shopsystem-web.service', configuration: cfg, install_dir: systemdsystemunitdir)
configure_file(input: 'shopsystem-display-on-off.service.in', output: 'shopsystem-display-on-off.service', configuration: cfg, install_dir: systemdsystemunitdir)
