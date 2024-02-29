/* window.c */
int window_layout_locked(enum CMD_index cmd);
win_T *prevwin_curwin(void);
win_T *swbuf_goto_win_with_buf(buf_T *buf);
void do_window(int nchar, long Prenum, int xchar);
void get_wincmd_addr_type(char_u *arg, exarg_T *eap);
int check_split_disallowed(win_T *wp);
int win_split(int size, int flags);
int win_splitmove(win_T *wp, int size, int flags);
int win_split_ins(int size, int flags, win_T *new_wp, int dir, frame_T *to_flatten);
int win_valid_popup(win_T *win);
int win_valid(win_T *win);
win_T *win_find_by_id(int id);
int win_valid_any_tab(win_T *win);
int win_count(void);
int make_windows(int count, int vertical);
void win_move_after(win_T *win1, win_T *win2);
void win_equal(win_T *next_curwin, int current, int dir);
void leaving_window(win_T *win);
void entering_window(win_T *win);
void curwin_init(void);
void close_windows(buf_T *buf, int keep_curwin);
int last_window(void);
int one_window(void);
int win_close(win_T *win, int free_buf);
void snapshot_windows_scroll_size(void);
void may_make_initial_scroll_size_snapshot(void);
void may_trigger_win_scrolled_resized(void);
void win_close_othertab(win_T *win, int free_buf, tabpage_T *tp);
void win_free_all(void);
win_T *winframe_remove(win_T *win, int *dirp, tabpage_T *tp, frame_T **unflat_altfr);
void close_others(int message, int forceit);
void unuse_tabpage(tabpage_T *tp);
void use_tabpage(tabpage_T *tp);
int win_alloc_first(void);
win_T *win_alloc_popup_win(void);
void win_init_popup_win(win_T *wp, buf_T *buf);
void win_init_size(void);
void free_tabpage(tabpage_T *tp);
int win_new_tabpage(int after);
int make_tabpages(int maxcount);
int valid_tabpage(tabpage_T *tpc);
int valid_tabpage_win(tabpage_T *tpc);
void close_tabpage(tabpage_T *tab);
tabpage_T *find_tabpage(int n);
int tabpage_index(tabpage_T *ftp);
void goto_tabpage(int n);
void goto_tabpage_tp(tabpage_T *tp, int trigger_enter_autocmds, int trigger_leave_autocmds);
int goto_tabpage_lastused(void);
void goto_tabpage_win(tabpage_T *tp, win_T *wp);
void tabpage_move(int nr);
void win_goto(win_T *wp);
win_T *win_find_nr(int winnr);
tabpage_T *win_find_tabpage(win_T *win);
win_T *win_vert_neighbor(tabpage_T *tp, win_T *wp, int up, long count);
win_T *win_horz_neighbor(tabpage_T *tp, win_T *wp, int left, long count);
void win_enter(win_T *wp, int undo_sync);
win_T *buf_jump_open_win(buf_T *buf);
win_T *buf_jump_open_tab(buf_T *buf);
int win_unlisted(win_T *wp);
void win_free_popup(win_T *win);
void win_remove(win_T *wp, tabpage_T *tp);
int win_alloc_lines(win_T *wp);
void win_free_lsize(win_T *wp);
void shell_new_rows(void);
void shell_new_columns(void);
void win_size_save(garray_T *gap);
void win_size_restore(garray_T *gap);
int win_comp_pos(void);
void win_ensure_size(void);
void win_setheight(int height);
void win_setheight_win(int height, win_T *win);
void win_setwidth(int width);
void win_setwidth_win(int width, win_T *wp);
void win_setminheight(void);
void win_setminwidth(void);
void win_drag_status_line(win_T *dragwin, int offset);
void win_drag_vsep_line(win_T *dragwin, int offset);
void set_fraction(win_T *wp);
void win_new_height(win_T *wp, int height);
void scroll_to_fraction(win_T *wp, int prev_height);
void win_new_width(win_T *wp, int width);
void win_comp_scroll(win_T *wp);
void command_height(void);
void last_status(int morewin);
int tabline_height(void);
int last_stl_height(int morewin);
int min_rows(void);
int only_one_window(void);
void check_lnums(int do_curwin);
void check_lnums_nested(int do_curwin);
void reset_lnums(void);
int make_snapshot(int idx);
void restore_snapshot(int idx, int close_curwin);
int win_hasvertsplit(void);
int get_win_number(win_T *wp, win_T *first_win);
int get_tab_number(tabpage_T *tp);
char *check_colorcolumn(win_T *wp);
int get_last_winid(void);
/* vim: set ft=c : */
