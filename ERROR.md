[+] Compiling amdgpu module with 12 jobs...
../pm/swsmu/smu_cmn.c: In function 'smu_cmn_send_raw_smc_msg':
../pm/swsmu/smu_cmn.c:1222:39: error: 'struct smu_context' has no member named 'msg_ctl'
1222 |         struct smu_msg_ctl *ctl = &smu->msg_ctl;
	 |                                       ^~
../pm/swsmu/smu_cmn.c:1223:42: error: invalid use of undefined type 'struct smu_msg_ctl'
1223 |         struct smu_msg_config *cfg = &ctl->config;
	 |                                          ^~
../pm/swsmu/smu_cmn.c:1229:24: error: invalid use of undefined type 'struct smu_msg_ctl'
1229 |         mutex_lock(&ctl->lock);
	 |                        ^~
../pm/swsmu/smu_cmn.c:1232:34: error: invalid use of undefined type 'struct smu_msg_ctl'
1232 |                 mutex_unlock(&ctl->lock);
	 |                                  ^~
../pm/swsmu/smu_cmn.c:1238:23: error: implicit declaration of function '__smu_msg_v1_poll_stat'; did you mean '__smu_cmn_poll_stat'? [-Wimplicit-function-declaration]
1238 |                 (void)__smu_msg_v1_poll_stat(ctl, 0); /* drain pending */
	 |                       ^~~~~~~~~~~~~~~~~~~~~~
	 |                       __smu_cmn_poll_stat
In file included from ../pm/swsmu/smu_cmn.c:25:
../pm/swsmu/smu_cmn.c:1240:19: error: invalid use of undefined type 'struct smu_msg_config'
1240 |         WREG32(cfg->resp_reg, 0);
	 |                   ^~
././../amdgpu/amdgpu.h:1445:50: note: in definition of macro 'WREG32'
1445 | #define WREG32(reg, v) amdgpu_device_wreg(adev, (reg), (v), 0)
	 |                                                  ^~~
../pm/swsmu/smu_cmn.c:1241:16: error: invalid use of undefined type 'struct smu_msg_config'
1241 |         if (cfg->num_arg_regs > 0)
	 |                ^~
../pm/swsmu/smu_cmn.c:1242:27: error: invalid use of undefined type 'struct smu_msg_config'
1242 |                 WREG32(cfg->arg_regs[0], param);
	 |                           ^~
././../amdgpu/amdgpu.h:1445:50: note: in definition of macro 'WREG32'
1445 | #define WREG32(reg, v) amdgpu_device_wreg(adev, (reg), (v), 0)
	 |                                                  ^~~
../pm/swsmu/smu_cmn.c:1246:16: error: invalid use of undefined type 'struct smu_msg_config'
1246 |         if (cfg->num_arg_regs > 1)
	 |                ^~
../pm/swsmu/smu_cmn.c:1247:27: error: invalid use of undefined type 'struct smu_msg_config'
1247 |                 WREG32(cfg->arg_regs[1], extra);
	 |                           ^~
././../amdgpu/amdgpu.h:1445:50: note: in definition of macro 'WREG32'
1445 | #define WREG32(reg, v) amdgpu_device_wreg(adev, (reg), (v), 0)
	 |                                                  ^~~
../pm/swsmu/smu_cmn.c:1248:21: error: invalid use of undefined type 'struct smu_msg_config'
1248 |         else if (cfg->num_arg_regs == 1)
	 |                     ^~
../pm/swsmu/smu_cmn.c:1249:27: error: invalid use of undefined type 'struct smu_msg_config'
1249 |                 WREG32(cfg->arg_regs[0] - 1, extra);
	 |                           ^~
././../amdgpu/amdgpu.h:1445:50: note: in definition of macro 'WREG32'
1445 | #define WREG32(reg, v) amdgpu_device_wreg(adev, (reg), (v), 0)
	 |                                                  ^~~
../pm/swsmu/smu_cmn.c:1250:19: error: invalid use of undefined type 'struct smu_msg_config'
1250 |         WREG32(cfg->msg_reg, raw_msg_index);
	 |                   ^~
././../amdgpu/amdgpu.h:1445:50: note: in definition of macro 'WREG32'
1445 | #define WREG32(reg, v) amdgpu_device_wreg(adev, (reg), (v), 0)
	 |                                                  ^~~
../pm/swsmu/smu_cmn.c:1254:27: error: invalid use of undefined type 'struct smu_msg_config'
1254 |         if (arg_out && cfg->num_arg_regs > 0)
	 |                           ^~
../pm/swsmu/smu_cmn.c:1255:38: error: invalid use of undefined type 'struct smu_msg_config'
1255 |                 *arg_out = RREG32(cfg->arg_regs[0]);
	 |                                      ^~
././../amdgpu/amdgpu.h:1443:47: note: in definition of macro 'RREG32'
1443 | #define RREG32(reg) amdgpu_device_rreg(adev, (reg), 0)
	 |                                               ^~~
../pm/swsmu/smu_cmn.c:1257:26: error: invalid use of undefined type 'struct smu_msg_ctl'
1257 |         mutex_unlock(&ctl->lock);
	 |                          ^~
make[3]: *** [/tmp/bc250-40cu-build/linux-6.18.53/scripts/Makefile.build:287: ../pm/swsmu/smu_cmn.o] Error 1
make[3]: *** Waiting for unfinished jobs....
make[2]: *** [/tmp/bc250-40cu-build/linux-6.18.53/Makefile:2050: .] Error 2
make[1]: *** [/tmp/bc250-40cu-build/linux-6.18.53/Makefile:248: __sub-make] Error 2
make: *** [Makefile:248: __sub-make] Error 2
[E] Compilation failed: amdgpu.ko not generated
