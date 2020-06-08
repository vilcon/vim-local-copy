/* typval.c */
typval_T *alloc_tv(void);
typval_T *alloc_string_tv(char_u *s);
void free_tv(typval_T *varp);
void clear_tv(typval_T *varp);
void init_tv(typval_T *varp);
int tv_check_lock(typval_T *tv, char_u *name, int use_gettext);
void copy_tv(typval_T *from, typval_T *to);
int typval_compare(typval_T *typ1, typval_T *typ2, exptype_T type, int ic);
char_u *typval_tostring(typval_T *arg);
int tv_islocked(typval_T *tv);
int tv_equal(typval_T *tv1, typval_T *tv2, int ic, int recursive);
int get_option_tv(char_u **arg, typval_T *rettv, int evaluate);
int get_number_tv(char_u **arg, typval_T *rettv, int evaluate, int want_string);
int get_string_tv(char_u **arg, typval_T *rettv, int evaluate);
int get_lit_string_tv(char_u **arg, typval_T *rettv, int evaluate);
char_u *tv2string(typval_T *tv, char_u **tofree, char_u *numbuf, int copyID);
int get_env_tv(char_u **arg, typval_T *rettv, int evaluate);
varnumber_T tv_get_number(typval_T *varp);
varnumber_T tv_get_number_chk(typval_T *varp, int *denote);
float_T tv_get_float(typval_T *varp);
char_u *tv_get_string(typval_T *varp);
char_u *tv_get_string_buf(typval_T *varp, char_u *buf);
char_u *tv_get_string_chk(typval_T *varp);
char_u *tv_get_string_buf_chk(typval_T *varp, char_u *buf);
linenr_T tv_get_lnum(typval_T *argvars);
linenr_T tv_get_lnum_buf(typval_T *argvars, buf_T *buf);
buf_T *tv_get_buf(typval_T *tv, int curtab_only);
char_u *tv_stringify(typval_T *varp, char_u *buf);
/* vim: set ft=c : */
