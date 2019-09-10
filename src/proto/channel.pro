/* channel.c */
void ch_logfile(char_u *fname, char_u *opt);
int ch_log_active(void);
channel_T *add_channel(void);
int has_any_channel(void);
int channel_unref(channel_T *channel);
int free_unused_channels_contents(int copyID, int mask);
void free_unused_channels(int copyID, int mask);
void channel_gui_register_all(void);
channel_T *channel_open(char *hostname, int port_in, int waittime, void (*nb_close_cb)(void));
channel_T *channel_listen(char *hostname, int port_in, void (*nb_close_cb)(void));
channel_T *channel_listen_func(typval_T *argvars);
void channel_set_pipes(channel_T *channel, sock_T in, sock_T out, sock_T err);
void channel_set_job(channel_T *channel, job_T *job, jobopt_T *options);
void channel_buffer_free(buf_T *buf);
void channel_write_any_lines(void);
void channel_write_new_lines(buf_T *buf);
readq_T *channel_peek(channel_T *channel, ch_part_T part);
char_u *channel_first_nl(readq_T *node);
char_u *channel_get(channel_T *channel, ch_part_T part, int *outlen);
void channel_consume(channel_T *channel, ch_part_T part, int len);
int channel_collapse(channel_T *channel, ch_part_T part, int want_nl);
int channel_can_write_to(channel_T *channel);
int channel_is_open(channel_T *channel);
char *channel_status(channel_T *channel, int req_part);
void channel_close(channel_T *channel, int invoke_close_cb);
void channel_clear(channel_T *channel);
void channel_free_all(void);
void channel_handle_events(int only_keep_open);
int channel_any_keep_open(void);
void channel_set_nonblock(channel_T *channel, ch_part_T part);
int channel_send(channel_T *channel, ch_part_T part, char_u *buf_arg, int len_arg, char *fun);
int channel_poll_setup(int nfd_in, void *fds_in, int *towait);
int channel_poll_check(int ret_in, void *fds_in);
int channel_select_setup(int maxfd_in, void *rfds_in, void *wfds_in, struct timeval *tv, struct timeval **tvp);
int channel_select_check(int ret_in, void *rfds_in, void *wfds_in);
int channel_parse_messages(void);
int channel_any_readahead(void);
int set_ref_in_channel(int copyID);
void clear_job_options(jobopt_T *opt);
int get_job_options(typval_T *tv, jobopt_T *opt, int supported, int supported2);
void job_free_all(void);
int job_any_running(void);
int win32_build_cmd(list_T *l, garray_T *gap);
void job_cleanup(job_T *job);
int set_ref_in_job(int copyID);
void job_unref(job_T *job);
int free_unused_jobs_contents(int copyID, int mask);
void free_unused_jobs(int copyID, int mask);
job_T *job_alloc(void);
void job_set_options(job_T *job, jobopt_T *opt);
void job_stop_on_exit(void);
int has_pending_job(void);
int job_check_ended(void);
job_T *job_start(typval_T *argvars, char **argv_arg, jobopt_T *opt_arg, int is_terminal);
char *job_status(job_T *job);
int job_stop(job_T *job, typval_T *argvars, char *type);
void invoke_prompt_callback(void);
int invoke_prompt_interrupt(void);
void f_prompt_setcallback(typval_T *argvars, typval_T *rettv);
void f_prompt_setinterrupt(typval_T *argvars, typval_T *rettv);
void f_prompt_setprompt(typval_T *argvars, typval_T *rettv);
void f_ch_canread(typval_T *argvars, typval_T *rettv);
void f_ch_close(typval_T *argvars, typval_T *rettv);
void f_ch_close_in(typval_T *argvars, typval_T *rettv);
void f_ch_getbufnr(typval_T *argvars, typval_T *rettv);
void f_ch_getjob(typval_T *argvars, typval_T *rettv);
void f_ch_info(typval_T *argvars, typval_T *rettv);
void f_ch_listen(typval_T *argvars, typval_T *rettv);
void f_ch_log(typval_T *argvars, typval_T *rettv);
void f_ch_logfile(typval_T *argvars, typval_T *rettv);
void f_ch_open(typval_T *argvars, typval_T *rettv);
void f_ch_read(typval_T *argvars, typval_T *rettv);
void f_ch_readblob(typval_T *argvars, typval_T *rettv);
void f_ch_readraw(typval_T *argvars, typval_T *rettv);
void f_ch_evalexpr(typval_T *argvars, typval_T *rettv);
void f_ch_sendexpr(typval_T *argvars, typval_T *rettv);
void f_ch_evalraw(typval_T *argvars, typval_T *rettv);
void f_ch_sendraw(typval_T *argvars, typval_T *rettv);
void f_ch_setoptions(typval_T *argvars, typval_T *rettv);
void f_ch_status(typval_T *argvars, typval_T *rettv);
void f_job_getchannel(typval_T *argvars, typval_T *rettv);
void f_job_info(typval_T *argvars, typval_T *rettv);
void f_job_setoptions(typval_T *argvars, typval_T *rettv);
void f_job_start(typval_T *argvars, typval_T *rettv);
void f_job_status(typval_T *argvars, typval_T *rettv);
void f_job_stop(typval_T *argvars, typval_T *rettv);
/* vim: set ft=c : */
