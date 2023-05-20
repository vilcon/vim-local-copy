/* gui_gtk_x11.c */
void gui_mch_prepare(int *argc, char **argv);
void gui_mch_free_all(void);
int gui_mch_is_blinking(void);
int gui_mch_is_blink_off(void);
void gui_mch_set_blinking(long waittime, long on, long off);
void gui_mch_stop_blink(int may_call_gui_update_cursor);
void gui_mch_start_blink(void);
int gui_mch_early_init_check(int give_message);
int gui_mch_init_check(void);
void gui_mch_set_dark_theme(void);
void gui_mch_show_tabline(int showit);
int gui_mch_showing_tabline(void);
void gui_mch_update_tabline(void);
void gui_mch_set_curtab(int nr);
void gui_gtk_set_selection_targets(void);
void gui_gtk_set_dnd_targets(void);
int gui_mch_init(void);
void gui_mch_forked(void);
void gui_mch_new_colors(void);
void gui_gtk_get_screen_geom_of_win(GtkWidget *wid, int point_x, int point_y, int *screen_x, int *screen_y, int *width, int *height);
void gui_mch_get_screen_dimensions(int *screen_w, int *screen_h);
int gui_mch_open(void);
void gui_mch_exit(int rc);
int gui_mch_get_winpos(int *x, int *y);
void gui_mch_set_winpos(int x, int y);
int gui_mch_maximized(void);
void gui_mch_unmaximize(void);
void gui_mch_newfont(void);
void gui_mch_set_shellsize(int width, int height, int min_width, int min_height, int base_width, int base_height, int direction);
void gui_mch_settitle(char_u *title, char_u *icon);
void gui_mch_enable_menu(int showit);
void gui_mch_show_toolbar(int showit);
int gui_mch_adjust_charheight(void);
char_u *gui_mch_font_dialog(char_u *oldval);
int gui_mch_init_font(char_u *font_name, int fontset);
GuiFont gui_mch_get_font(char_u *name, int report_error);
char_u *gui_mch_get_fontname(GuiFont font, char_u *name);
void gui_mch_free_font(GuiFont font);
guicolor_T gui_mch_get_color(char_u *name);
guicolor_T gui_mch_get_rgb_color(int r, int g, int b);
void gui_mch_set_fg_color(guicolor_T color);
void gui_mch_set_bg_color(guicolor_T color);
void gui_mch_set_sp_color(guicolor_T color);
int gui_gtk2_draw_string(int row, int col, char_u *s, int len, int flags);
int gui_gtk2_draw_string_ext(int row, int col, char_u *s, int len, int flags, int force_pango);
int gui_mch_haskey(char_u *name);
int gui_get_x11_windis(Window *win, Display **dis);
Display *gui_mch_get_display(void);
void gui_mch_beep(void);
void gui_mch_flash(int msec);
void gui_mch_invert_rectangle(int r, int c, int nr, int nc);
void gui_mch_iconify(void);
void gui_mch_set_foreground(void);
void gui_mch_draw_hollow_cursor(guicolor_T color);
void gui_mch_draw_part_cursor(int w, int h, guicolor_T color);
void gui_mch_update(void);
int gui_mch_wait_for_chars(long wtime);
void gui_mch_flush(void);
void gui_mch_clear_block(int row1arg, int col1arg, int row2arg, int col2arg);
void gui_mch_clear_all(void);
void gui_mch_delete_lines(int row, int num_lines);
void gui_mch_insert_lines(int row, int num_lines);
void clip_mch_request_selection(Clipboard_T *cbd);
void clip_mch_lose_selection(Clipboard_T *cbd);
int clip_mch_own_selection(Clipboard_T *cbd);
void clip_mch_set_selection(Clipboard_T *cbd);
int clip_gtk_owner_exists(Clipboard_T *cbd);
void gui_mch_menu_grey(vimmenu_T *menu, int grey);
void gui_mch_menu_hidden(vimmenu_T *menu, int hidden);
void gui_mch_draw_menubar(void);
void gui_mch_enable_scrollbar(scrollbar_T *sb, int flag);
guicolor_T gui_mch_get_rgb(guicolor_T pixel);
void gui_mch_getmouse(int *x, int *y);
void gui_mch_setmouse(int x, int y);
void gui_mch_mousehide(int hide);
void mch_set_mouse_shape(int shape);
void gui_mch_drawsign(int row, int col, int typenr);
void *gui_mch_register_sign(char_u *signfile);
void gui_mch_destroy_sign(void *sign);
/* vim: set ft=c : */
