[+] Applying 24 selected patches...
[+] 24 patches applied successfully.
[+] Configuring kernel configuration...
[+] Preparing kernel source tree (this may take a moment)...
[+] Compiling amdgpu module with 12 jobs...
In file included from /tmp/bc250-40cu-build/linux-6.18.53/include/linux/device.h:15,
                 from /tmp/bc250-40cu-build/linux-6.18.53/include/linux/pci.h:37,
                 from gmc_v10_0.c:25:
gmc_v10_0.c: In function 'gmc_v10_0_process_interrupt':
gmc_v10_0.c:209:28: error: 'AMDGPU_GMC9_FAULT_SOURCE_DATA_RETRY' undeclared (first use in this function)
  209 |                            AMDGPU_GMC9_FAULT_SOURCE_DATA_RETRY),
      |                            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/tmp/bc250-40cu-build/linux-6.18.53/include/linux/dev_printk.h:110:37: note: in definition of macro 'dev_printk_index_wrap'
  110 |                 _p_func(dev, fmt, ##__VA_ARGS__);                       \
      |                                     ^~~~~~~~~~~
gmc_v10_0.c:205:17: note: in expansion of macro 'dev_err'
  205 |                 dev_err(adev->dev,
      |                 ^~~~~~~
gmc_v10_0.c:209:28: note: each undeclared identifier is reported only once for each function it appears in
  209 |                            AMDGPU_GMC9_FAULT_SOURCE_DATA_RETRY),
      |                            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/tmp/bc250-40cu-build/linux-6.18.53/include/linux/dev_printk.h:110:37: note: in definition of macro 'dev_printk_index_wrap'
  110 |                 _p_func(dev, fmt, ##__VA_ARGS__);                       \
      |                                     ^~~~~~~~~~~
gmc_v10_0.c:205:17: note: in expansion of macro 'dev_err'
  205 |                 dev_err(adev->dev,
      |                 ^~~~~~~
gmc_v10_0.c:211:28: error: 'AMDGPU_GMC9_FAULT_SOURCE_DATA_EXE' undeclared (first use in this function)
  211 |                            AMDGPU_GMC9_FAULT_SOURCE_DATA_EXE),
      |                            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/tmp/bc250-40cu-build/linux-6.18.53/include/linux/dev_printk.h:110:37: note: in definition of macro 'dev_printk_index_wrap'
  110 |                 _p_func(dev, fmt, ##__VA_ARGS__);                       \
      |                                     ^~~~~~~~~~~
gmc_v10_0.c:205:17: note: in expansion of macro 'dev_err'
  205 |                 dev_err(adev->dev,
      |                 ^~~~~~~
gmc_v10_0.c:213:28: error: 'AMDGPU_GMC9_FAULT_SOURCE_DATA_WRITE' undeclared (first use in this function)
  213 |                            AMDGPU_GMC9_FAULT_SOURCE_DATA_WRITE));
      |                            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
/tmp/bc250-40cu-build/linux-6.18.53/include/linux/dev_printk.h:110:37: note: in definition of macro 'dev_printk_index_wrap'
  110 |                 _p_func(dev, fmt, ##__VA_ARGS__);                       \
      |                                     ^~~~~~~~~~~
gmc_v10_0.c:205:17: note: in expansion of macro 'dev_err'
  205 |                 dev_err(adev->dev,
      |                 ^~~~~~~
make[3]: *** [/tmp/bc250-40cu-build/linux-6.18.53/scripts/Makefile.build:287: gmc_v10_0.o] Error 1
make[3]: *** Waiting for unfinished jobs....
make[2]: *** [/tmp/bc250-40cu-build/linux-6.18.53/Makefile:2050: .] Error 2
make[1]: *** [/tmp/bc250-40cu-build/linux-6.18.53/Makefile:248: __sub-make] Error 2
make: *** [Makefile:248: __sub-make] Error 2
[E] Compilation failed: amdgpu.ko not generated.
