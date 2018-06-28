udev = dependency('udev')
udevdir = udev.get_pkgconfig_variable('udevdir')
rulesdir = join_paths(udevdir, 'rules.d')

install_data('shopsystem-input-device-rfid.rules', install_dir: rulesdir)
install_data('shopsystem-input-device.rules', install_dir: rulesdir)
