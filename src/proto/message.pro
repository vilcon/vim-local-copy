/* message.c */
int msg(char *s);
int verb_msg(char *s);
int msg_attr(char *s, int attr);
int msg_attr_keep(char *s, int attr, int keep);
char_u *msg_strtrunc(char_u *s, int force);
void trunc_string(char_u *s, char_u *buf, int room_in, int buflen);
void reset_last_sourcing(void);
void msg_source(int attr);
void ignore_error_for_testing(char_u *error);
void do_perror(char *msg);
int emsg(char *s);
void iemsg(char *s);
void internal_error(char *where);
void internal_error_no_abort(char *where);
void emsg_invreg(int name);
void emsg_namelen(char *msg, char_u *name, int len);
char *msg_trunc_attr(char *s, int force, int attr);
char_u *msg_may_trunc(int force, char_u *s);
int delete_first_msg(void);
void ex_messages(exarg_T *eap);
void msg_end_prompt(void);
void wait_return(int redraw);
void set_keep_msg(char_u *s, int attr);
void set_keep_msg_from_hist(void);
void msg_start(void);
void msg_starthere(void);
void msg_putchar(int c);
void msg_putchar_attr(int c, int attr);
void msg_outnum(long n);
void msg_home_replace(char_u *fname);
void msg_home_replace_hl(char_u *fname);
int msg_outtrans(char_u *str);
int msg_outtrans_attr(char_u *str, int attr);
int msg_outtrans_len(char_u *str, int len);
char_u *msg_outtrans_one(char_u *p, int attr);
int msg_outtrans_len_attr(char_u *msgstr, int len, int attr);
void msg_make(char_u *arg);
int msg_outtrans_special(char_u *strstart, int from, int maxlen);
char_u *str2special_save(char_u *str, int replace_spaces, int replace_lt);
char_u *str2special(char_u **sp, int replace_spaces, int replace_lt);
void str2specialbuf(char_u *sp, char_u *buf, int len);
void msg_prt_line(char_u *s, int list);
void msg_puts(char *s);
void msg_puts_title(char *s);
void msg_outtrans_long_attr(char_u *longstr, int attr);
void msg_puts_attr(char *s, int attr);
int message_filtered(char_u *msg);
void may_clear_sb_text(void);
void sb_text_start_cmdline(void);
void sb_text_restart_cmdline(void);
void sb_text_end_cmdline(void);
void clear_sb_text(int all);
void show_sb_text(void);
void msg_sb_eol(void);
int msg_use_printf(void);
void mch_errmsg(char *str);
void mch_msg(char *str);
void repeat_message(void);
void msg_clr_eos(void);
void msg_clr_eos_force(void);
void msg_clr_cmdline(void);
int msg_end(void);
void msg_check(void);
int redirecting(void);
void verbose_enter(void);
void verbose_leave(void);
void verbose_enter_scroll(void);
void verbose_leave_scroll(void);
void verbose_stop(void);
int verbose_open(void);
void give_warning(char_u *message, int hl);
void give_warning_with_source(char_u *message, int hl, int with_source);
void give_warning2(char_u *message, char_u *a1, int hl);
void msg_advance(int col);
int do_dialog(int type, char_u *title, char_u *message, char_u *buttons, int dfltbutton, char_u *textfield, int ex_cmd);
int vim_dialog_yesno(int type, char_u *title, char_u *message, int dflt);
int vim_dialog_yesnocancel(int type, char_u *title, char_u *message, int dflt);
int vim_dialog_yesnoallcancel(int type, char_u *title, char_u *message, int dflt);
void add_msg_hist(char_u *s, int len, int attr);
/* vim: set ft=c : */
