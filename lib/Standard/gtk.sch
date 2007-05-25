(require 'std-ffi)
(require 'foreign-stdlib)
(require 'foreign-sugar)
(require 'foreign-ctools)
(require 'foreign-cenums)
(require 'srfi-0)
(require 'glib) ;; convenience; who's going to use gtk without glib?
(require 'gdk)

(let ((os (assq 'os-name (system-features))))
  (cond 
   ((equal? os '(os-name . "Linux"))
    (foreign-file "/usr/lib/libgtk-x11-2.0.so.0"))    
   ((equal? os '(os-name . "SunOS"))
    (foreign-file "/usr/lib/libgtk-x11-2.0.so"))
   ((equal? os '(os-name . "MacOS X"))
    (foreign-file "/sw/lib/libgtk-x11-2.0.dylib")
    ;(foreign-file "~/Library/Gtk+-Cocoa.framework/Gtk+-Cocoa")
    )
   (else
    (error "Add case in gtk.sch for os: " os))))

;;; XXX perhaps we need a bit of type abstraction for callbacks
;;; like these, where we could abstract over what type should be
;;; ascribed to the callback argument.
;;;
;;; (But that's an absurd amount of machinery to add when one can
;;; easily get around the problem by passing closures as the callback,
;;; as would have been appropriate in the first place)

(define gtktextiter*-rt (ffi-install-void*-subtype 'gtktextiter*))
(establish-void*-subhierarchy! '(gtkclipboard*))
(establish-void*-subhierarchy! '(gtktextchildanchor*))

(establish-void*-subhierarchy!
 '(gobject* (gtkobject* 
             (gtkwidget* (gtkcontainer* 
                          (gtkbin* (gtkalignment*)
                                   (gtkwindow* (gtkdialog* (gtkfileselection*)))
                                   (gtkbutton* (gtktogglebutton*
                                                (gtkcheckbutton*
                                                 (gtkradiobutton*)))
                                               (gtkoptionmenu*))
                                   (gtkcombobox*)
                                   (gtktoolitem* (gtktoolbutton*))
                                   (gtkframe*)
                                   (gtkitem* (gtkmenuitem*
                                              (gtkcheckmenuitem*
                                               (gtkradiomenuitem*))
                                              (gtkimagemenuitem*)
                                              (gtkseparatormenuitem*)
                                              (gtktearoffmenuitem*))))
                          (gtkbox* (gtkvbox*)
                                   (gtkhbox*
                                    (gtkcombo*)))
                          (gtktable*)
                          (gtktoolbar*)
                          (gtkmenushell* (gtkmenubar*)
                                         (gtkmenu*))
                          (gtktextview*)) ;; end gtkcontainer*
                         (gtkmisc* (gtklabel*)
                                   (gtkarrow*)
                                   (gtkimage*)
                                   (gtkpixmap*))
                         (gtkrange* (gtkscale*)
                                    (gtkscrollbar*))
                         (gtkprogress* (gtkprogressbar*))
;; Deprecated in gtk2
;                         (gtktext*)
                         )
             (gtktooltips*)
             (gtkadjustment*))
            (gtkaccelgroup*)
            (gtktextbuffer*)
            (gtktextmark*)
            (gtktexttagtable*)
            (gtktexttag*)
            ))

(define gtk-init 
  (let ()
    (define-foreign (gtk-init void* void*) void)
    (lambda arg-strings
      (let ((string-vec (list->vector (cons "larceny" arg-strings))))
        (call-with-char** string-vec
                          (lambda (argv)
                            (call-with-boxed 
                             argv 
                             (lambda (&argv)
                               (call-with-boxed (vector-length string-vec)
                                                (lambda (&argc)
                                                  (gtk-init &argc &argv)))))))))))

(define-foreign (gtk-window-new int) gtkwindow*)
(define-foreign (gtk-widget-show gtkwidget*) void)
(define-foreign (gtk-widget-show-now gtkwidget*) void)
(define-foreign (gtk-widget-hide gtkwidget*) void)
(define-foreign (gtk-widget-show-all gtkwidget*) void)
(define-foreign (gtk-widget-hide-all gtkwidget*) void)
(define-foreign (gtk-widget-map gtkwidget*) void)
(define-foreign (gtk-widget-unmap gtkwidget*) void)
(define-foreign (gtk-widget-realize gtkwidget*) void)
(define-foreign (gtk-widget-unrealize gtkwidget*) void)
(define-foreign (gtk-widget-add-accelerator gtkwidget* string gtkaccelgroup* 
                                            char uint uint) 
  void)
(define-foreign (gtk-widget-get-parent gtkwidget*) gtkwidget*)
(define-foreign (gtk-widget-set-parent gtkwidget* gtkwidget*) void)
(define-foreign (gtk-widget-get-parent-window gtkwidget*) gdkwindow*)
(define-foreign (gtk-widget-set-parent-window gtkwidget* gdkwindow*) void)
(define-foreign (gtk-widget-grab-default gtkwidget*) void)
(define-foreign (gtk-widget-grab-focus gtkwidget*) void)
(define-foreign (gtk-grab-add gtkwidget*) void)
(define-foreign (gtk-grab-get-current) gtkwidget*)
(define-foreign (gtk-grab-remove gtkwidget*) void)
(define (gtk-widget-set-flags widget flags)
  (void*-word-set! widget gtkobject-flags-offset 
                   (fxlogior 
                    (void*-word-ref widget gtkobject-flags-offset)
                    flags)))

(define-foreign (gtk-main) void)
(define-foreign (gtk-main-level) uint)
(define-foreign (gtk-main-quit) void)
(define-foreign (gtk-main-iteration) bool)
(define-foreign (gtk-main-iteration-do bool) bool)
(define-foreign (gtk-timeout-add uint (-> (void*) bool) (maybe void*)) uint)
(define-foreign (gtk-timeout-remove uint) void)
(define-foreign (gtk-events-pending) bool)
(define-foreign (gtk-exit int) void)


(define-foreign (gtk-container-set-border-width! gtkcontainer* int) void)
(define-foreign (gtk-button-new-with-label string) gtkbutton*)
(define-foreign (gtk-container-add gtkcontainer* gtkwidget*) void)
(define-foreign (gtk-window-set-title! gtkwindow* string) void)
(define-foreign (gtk-window-set-resizable! gtkwindow* bool) void)
(define-foreign (gtk-hbox-new bool int) gtkhbox*)
(define-foreign (gtk-vbox-new bool int) gtkvbox*)
(define-foreign (gtk-label-new string) gtkwidget*)
(define-foreign (gtk-hseparator-new) gtkwidget*)
(define-foreign (gtk-box-pack-start gtkbox* gtkwidget* bool bool int) void)
(define-foreign (gtk-box-pack-end   gtkbox* gtkwidget* bool bool int) void)
(define-foreign (gtk-misc-set-alignment gtkmisc* float float) void)
(define-foreign (gtk-misc-set-padding gtkmisc* int int) void)
(define-foreign (gtk-widget-set-size-request gtkwidget* int int) void)
(define-foreign (gtk-table-new int int bool) gtkwidget*)
(define-foreign (gtk-table-attach-defaults gtktable* gtkwidget* int int int int)
  void)
(define-foreign (gtk-table-set-row-spacing gtktable* uint uint) void)
(define-foreign (gtk-image-new-from-file string) gtkwidget*)
(define-foreign (gtk-button-new) gtkwidget*)
(define-foreign (gtk-button-new-with-mnemonic string) gtkbutton*)
(define-foreign (gtk-button-pressed gtkbutton*) void)
(define-foreign (gtk-button-released gtkbutton*) void)
(define-foreign (gtk-button-clicked gtkbutton*) void)
(define-foreign (gtk-button-enter gtkbutton*) void)
(define-foreign (gtk-button-leave gtkbutton*) void)
(define-foreign (gtk-radio-button-new-with-label (maybe void*) string) 
  gtkradiobutton*)
(define-foreign (gtk-radio-button-new-with-label-from-widget 
                 gtkradiobutton* string) 
  gtkradiobutton*)
(define-foreign (gtk-radio-button-get-group gtkradiobutton*) void*)
(define-foreign (gtk-toggle-button-new) gtktogglebutton*)
(define-foreign (gtk-toggle-button-new-with-label string) gtktogglebutton*)
(define-foreign (gtk-toggle-button-new-with-mnemonic string) gtktogglebutton*)
(define-foreign (gtk-toggle-button-set-mode gtktogglebutton* bool) void)
(define-foreign (gtk-toggle-button-get-mode gtktogglebutton*) bool)
(define-foreign (gtk-toggle-button-set-active gtktogglebutton* bool) void)
(define-foreign (gtk-toggle-button-get-active gtktogglebutton*) bool)
(define-foreign (gtk-toggle-button-toggled gtktogglebutton*) void)
(define-foreign (gtk-toggle-button-set-inconsistent gtktogglebutton* bool) void)
(define-foreign (gtk-toggle-button-get-inconsistent gtktogglebutton*) bool)
(define-foreign (gtk-adjustment-new double double double double double double) gtkobject*)
(define-foreign (gtk-vscale-new gtkadjustment*) gtkwidget*)
(define-foreign (gtk-hscale-new gtkadjustment*) gtkwidget*)
(define-foreign (gtk-hscrollbar-new gtkadjustment*) gtkwidget*)
(define-foreign (gtk-vscrollbar-new gtkadjustment*) gtkwidget*)
(define-foreign (gtk-check-button-new-with-label string) gtkwidget*)
(define-foreign (gtk-range-set-update-policy gtkrange* int) void)
(define-foreign (gtk-scale-set-digits gtkscale* int) void)
(define-foreign (gtk-scale-set-value-pos gtkscale* int) void)
(define-foreign (gtk-scale-set-draw-value gtkscale* bool) void)
(define-foreign (gtk-menu-item-new-with-label string) gtkmenuitem*)
(define-foreign (gtk-menu-item-new) gtkmenuitem*)
(define-foreign (gtk-menu-new) gtkmenu*)
(define-foreign (gtk-option-menu-new) gtkoptionmenu*)
(define-foreign (gtk-menu-shell-append gtkmenushell* gtkwidget*) void)
(define-foreign (gtk-option-menu-set-menu gtkoptionmenu* gtkwidget*) void)
(define-foreign (gtk-frame-new string) gtkframe*)
(define-foreign (gtk-frame-set-shadow-type gtkframe* uint) void) ;; XXX should have abstract enum for GtkShadowType
(define-foreign (gtk-frame-get-shadow-type gtkframe*) uint)      ;; XXX see above...
(define-foreign (gtk-frame-set-label-align gtkframe* float float) void)
;; XXX need boxed floats to do get-frame-get-label-align...
(define-foreign (gtk-label-set-justify gtklabel* int) void)
(define-foreign (gtk-label-set-line-wrap gtklabel* bool) void)
(define-foreign (gtk-label-set-pattern gtklabel* string) void)
(define-foreign (gtk-label-get-text gtklabel*) string)
(define-foreign (gtk-label-set-text gtklabel* string) void)
(define-foreign (gtk-widget-show-all gtkwidget*) void)
(define-foreign (gtk-arrow-new int int) gtkwidget*)
(define-foreign (gtk-alignment-new float float float float) gtkalignment*)
(define-foreign (gtk-progress-bar-new) gtkprogressbar*)
(define-foreign (gtk-progress-bar-new-with-adjustment gtkadjustment*) gtkprogressbar*)
(define-foreign (gtk-table-attach gtktable* gtkwidget* 
                                  uint uint uint uint 
                                  unsigned unsigned 
                                  uint uint) 
  void)
(define-foreign (gtk-widget-destroy gtkwidget*) void)
(define-foreign (gtk-progress-bar-get-fraction gtkprogressbar*) double)
(define-foreign (gtk-progress-bar-set-fraction gtkprogressbar* double) void)
(define-foreign (gtk-progress-bar-get-text gtkprogressbar*) string)
(define-foreign (gtk-progress-bar-set-text gtkprogressbar* string) void)
(define-foreign (gtk-progress-bar-pulse gtkprogressbar*) void)
(define-foreign (gtk-progress-bar-get-orientation gtkprogressbar*) unsigned)
(define-foreign (gtk-progress-bar-set-orientation gtkprogressbar* unsigned) void)
(define-foreign (gtk-container-set-border-width gtkcontainer* uint) void)
(define-foreign (gtk-container-get-border-width gtkcontainer*) uint)


(define-foreign (gtk-tooltips-new) gtktooltips*)
(define-foreign (gtk-tooltips-set-tip gtktooltips* gtkwidget* string (maybe string)) void)

(define-foreign (gtk-menu-bar-new) gtkmenubar*)

(define-foreign (gtk-accel-group-new) gtkaccelgroup*)
;; (define-foreign (gtk-accel-group-attach void* void*) void) ;; XXX

(define-foreign (gtk-menu-item-set-submenu gtkmenuitem* gtkwidget*) void)
(define-foreign (gtk-menu-item-get-submenu gtkmenuitem*) gtkwidget*)

(define-foreign (gtk-check-menu-item-new) gtkcheckmenuitem*)
(define-foreign (gtk-check-menu-item-new-with-label string) gtkcheckmenuitem*)
(define-foreign (gtk-check-menu-item-new-with-mnemonic string) gtkcheckmenuitem*)
(define-foreign (gtk-check-menu-item-set-active gtkcheckmenuitem* bool) void)
(define-foreign (gtk-check-menu-item-get-active gtkcheckmenuitem*) bool)
(define-foreign (gtk-check-menu-item-toggled gtkcheckmenuitem*) void)
(define-foreign (gtk-check-menu-item-set-inconsistent gtkcheckmenuitem* bool) void)
(define-foreign (gtk-check-menu-item-get-inconsistent gtkcheckmenuitem*) bool)

(define-foreign (gtk-radio-menu-item-new (maybe void*)) gtkradiomenuitem*)
(define-foreign (gtk-radio-menu-item-new-with-label (maybe void*) string) gtkradiomenuitem*)
(define-foreign (gtk-radio-menu-item-new-with-mnemonic (maybe void*) string) gtkradiomenuitem*)
(define-foreign (gtk-radio-menu-item-get-group gtkradiomenuitem*) void*)
(define-foreign (gtk-radio-menu-item-set-group gtkradiomenuitem* (maybe void*)) void)

(define-foreign (gtk-toolbar-get-type) uint)
(define-foreign (gtk-toolbar-new) gtktoolbar*)
(define-foreign (gtk-toolbar-get-orientation gtktoolbar*) int)
(define-foreign (gtk-toolbar-set-orientation gtktoolbar* int) void)
(define-foreign (gtk-toolbar-get-tooltips gtktoolbar*) bool)
(define-foreign (gtk-toolbar-set-tooltips gtktoolbar* bool) void)
(define-foreign (gtk-toolbar-get-style gtktoolbar*) int)
(define-foreign (gtk-toolbar-set-style gtktoolbar* int) void)
(define-foreign (gtk-toolbar-append-item 
                 gtktoolbar* string string string gtkwidget* 
                 (-> (gtkwidget* void*) void) (maybe void*))
  void)
(define-foreign (gtk-toolbar-append-space gtktoolbar*) void)
(define-foreign (gtk-toolbar-append-widget gtktoolbar* gtkwidget* string string) void)
(define-foreign (gtk-toolbar-prepend-widget gtktoolbar* gtkwidget* string string) void)
(define-foreign (gtk-toolbar-insert-widget gtktoolbar* gtkwidget* string string int) void)
(define-foreign (gtk-toolbar-append-element 
                 gtktoolbar* uint (maybe gtkwidget*) 
                 (maybe string) string (maybe string) 
                 gtkwidget* (-> (gtkwidget* void*) void) (maybe void*)) 
  gtkwidget*)
(define-foreign (gtk-toolbar-prepend-element 
                 gtktoolbar* uint (maybe gtkwidget*) 
                 (maybe string) string (maybe string) 
                 gtkwidget* (-> (gtkwidget* void*) void) (maybe void*)) 
  void*)
(define-foreign (gtk-toolbar-prepend-element 
                 gtktoolbar* uint (maybe gtkwidget*)
                 (maybe string) string (maybe string) 
                 gtkwidget* (-> (gtkwidget* void*) void) (maybe void*) int) 
  gtkwidget*)

(define-foreign (gtk-pixmap-new gdkpixmap* (maybe gdkbitmap*)) gtkpixmap*)

(define-foreign (gtk-combo-new) gtkcombo*)
(define-foreign (gtk-combo-set-value-in-list gtkcombo* bool bool) void)
(define-foreign (gtk-combo-set-use-arrows gtkcombo* bool) void)
(define-foreign (gtk-combo-set-use-arrows-always gtkcombo* bool) void)
(define-foreign (gtk-combo-set-case-sensitive gtkcombo* bool) void)
(define-foreign (gtk-combo-set-item-string gtkcombo* gtkitem* string) void)
(define-foreign (gtk-combo-set-popdown-strings gtkcombo* glist*) void)
(define-foreign (gtk-combo-disable-activate gtkcombo*) void)

;; Deprecated in gtk2
;(define-foreign (gtk-text-new (maybe gtkadjustment*) (maybe gtkadjustment*)) gtktext*)
;(define-foreign (gtk-text-set-editable  gtktext* bool) void)
;(define-foreign (gtk-text-set-word-wrap gtktext* bool) void)
;(define-foreign (gtk-text-set-line-wrap gtktext* bool) void)
;(define-foreign (gtk-text-set-adjustments gtktext* gtkadjustment* gtkadjustment*) void)
;(define-foreign (gtk-text-set-point gtktext* uint) void)
;(define-foreign (gtk-text-get-point gtktext*) uint)
;(define-foreign (gtk-text-get-length gtktext*) uint)
;(define-foreign (gtk-text-freeze gtktext*) void)
;(define-foreign (gtk-text-thaw gtktext*) void)
;(define-foreign (gtk-text-insert gtktext* gdkfont* gdkcolor* gdkcolor* string int) void)
;(define-foreign (gtk-text-backward-delete gtktext* uint) bool)
;(define-foreign (gtk-text-forward-delete gtktext* uint) bool)

(define-foreign (gtk-text-view-new) gtktextview*)
(define-foreign (gtk-text-view-new-with-buffer gtktextbuffer*) gtktextview*)
(define-foreign (gtk-text-view-set-buffer gtktextview* gtktextbuffer*) void)
(define-foreign (gtk-text-view-get-buffer gtktextview*) gtktextbuffer*)
(define-foreign (gtk-text-view-scroll-to-mark gtktextview* 
                                              gtktextmark*
                                              double bool double double) void)
(define-foreign (gtk-text-view-scroll-to-iter gtktextview* gtktextiter* 
                                              double bool double double) void)
(define-foreign (gtk-text-view-scroll-mark-onscreen gtktextview* gtktextmark*) void)
(define-foreign (gtk-text-view-place-cursor-onscreen gtktextview*) bool)
(define-foreign (gtk-text-view-get-visible-rect gtktextview* gdkrectangle*) void)
(define-foreign (gtk-text-view-get-iter-location gtktextview* 
                                                 gtktextiter* gdkrectangle*) void)
(define-foreign (gtk-text-view-get-line-at-y gtktextview* 
                                             gtktextiter* int int*) void)
(define-foreign (gtk-text-view-get-line-yrange gtktextview* 
                                               gtktextiter* int* int*) void)
(define-foreign (gtk-text-view-get-iter-at-location gtktextview* 
                                                    gtktextiter* int int) void)
(define-foreign (gtk-text-view-get-iter-at-position gtktextview* 
                                                    gtktextiter* int* int int) void)
(define-foreign (gtk-text-view-buffer-to-window-coords gtktextview*
                                                       uint int int int* int*) void)
(define-foreign (gtk-text-view-window-to-buffer-coords gtktextview*
                                                       uint int int int* int*) void)
(define-foreign (gtk-text-view-get-window gtktextview* uint) gdkwindow*)
(define-foreign (gtk-text-view-get-window-type gtktextview* gdkwindow*) uint)
(define-foreign (gtk-text-view-set-border-window-size gtktextview* uint int) void)
(define-foreign (gtk-text-view-get-border-window-size gtktextview* uint) int)
(define-foreign (gtk-text-view-forward-display-line gtktextview* gtktextiter*) bool)
(define-foreign (gtk-text-view-backward-display-line gtktextview* gtktextiter*) bool)
(define-foreign (gtk-text-view-forward-display-line-end gtktextview* gtktextiter*) bool)
(define-foreign (gtk-text-view-backward-display-line-start gtktextview* gtktextiter*) bool)
(define-foreign (gtk-text-view-starts-display-line gtktextview* gtktextiter*) bool)
(define-foreign (gtk-text-view-move-visually gtktextview* gtktextiter* int) bool)
(define-foreign (gtk-text-view-add-child-at-anchor gtktextview* 
                                                   gtkwidget* gtktextchildanchor*) void)
(define-foreign (gtk-text-child-anchor-new) gtktextchildanchor*)
(define-foreign (gtk-text-child-anchor-get-widgets gtktextchildanchor*) glist*)
(define-foreign (gtk-text-child-anchor-get-deleted gtktextchildanchor*) glist*)
(define-foreign (gtk-text-view-add-child-in-window gtktextview* 
                                                   gtkwidget* uint int int) void)
(define-foreign (gtk-text-view-move-child gtktextview* gtkwidget* int int) void)
(define-foreign (gtk-text-view-set-wrap-mode gtktextview* uint) void)
(define-foreign (gtk-text-view-get-wrap-mode gtktextview*) uint)
(define-foreign (gtk-text-view-set-editable gtktextview* bool) void)
(define-foreign (gtk-text-view-get-editable gtktextview*) bool)
(define-foreign (gtk-text-view-set-cursor-visible gtktextview* bool) void)
(define-foreign (gtk-text-view-get-cursor-visible gtktextview*) bool)
(define-foreign (gtk-text-view-set-overwrite gtktextview* bool) void)
(define-foreign (gtk-text-view-get-overwrite gtktextview*) bool)
(define-foreign (gtk-text-view-set-pixels-above-lines gtktextview* int) void)
(define-foreign (gtk-text-view-get-pixels-above-lines gtktextview*) int)
(define-foreign (gtk-text-view-set-pixels-below-lines gtktextview* int) void)
(define-foreign (gtk-text-view-get-pixels-below-lines gtktextview*) int)
(define-foreign (gtk-text-view-set-pixels-inside-wrap gtktextview* int) void)
(define-foreign (gtk-text-view-get-pixels-inside-wrap gtktextview*) int)

(define-foreign (gtk-text-buffer-new (maybe gtktexttagtable*)) gtktextbuffer*)
(define-foreign (gtk-text-buffer-get-line-count gtktextbuffer*) int)
(define-foreign (gtk-text-buffer-get-char-count gtktextbuffer*) int)
(define-foreign (gtk-text-buffer-get-tag-table gtktextbuffer*) gtktexttagtable*)
(define-foreign (gtk-text-buffer-set-text gtktextbuffer* string int) void)
(define-foreign (gtk-text-buffer-insert gtktextbuffer* gtktextiter* string int) void)
(define-foreign (gtk-text-buffer-insert-at-cursor gtktextbuffer* string int) void)
(define-foreign (gtk-text-buffer-insert-interactive gtktextbuffer* gtktextiter* string int bool) bool)
(define-foreign (gtk-text-buffer-insert-interactive-at-cursor gtktextbuffer* string int bool) bool)
(define-foreign (gtk-text-buffer-insert-range gtktextbuffer* gtktextiter* gtktextiter* gtktextiter*) void)
(define-foreign (gtk-text-buffer-insert-range-interactive gtktextbuffer* gtktextiter* gtktextiter* gtktextiter* bool) bool)
;; can't handle varargs with define-foreign
;(define-foreign (gtk-text-buffer-insert-with-tags gtktextbuffer* gtktextiter* string int gtktexttag* ...) void)
;(define-foreign (gtk-text-buffer-insert-with-tags-by-name gtktextbuffer* gtktextiter* string int string ...) void)
(define-foreign (gtk-text-buffer-delete gtktextbuffer* gtktextiter* gtktextiter*) void)
(define-foreign (gtk-text-buffer-delete-interactive gtktextbuffer* gtktextiter* gtktextiter* bool) bool)
(define-foreign (gtk-text-buffer-backspace gtktextbuffer* gtktextiter* bool bool) bool)
(define-foreign (gtk-text-buffer-get-text gtktextbuffer* gtktextiter* gtktextiter* bool) string)
(define-foreign (gtk-text-buffer-get-slice gtktextbuffer* gtktextiter* gtktextiter* bool) string)
(define-foreign (gtk-text-buffer-insert-pixbuf gtktextbuffer* gtktextiter* gdkpixbuf*) void)
(define-foreign (gtk-text-buffer-insert-child-anchor gtktextbuffer* gtktextiter* gtktextchildanchor*) void)
(define-foreign (gtk-text-buffer-create-child-anchor gtktextbuffer* gtktextiter*) gtktextchildanchor*)
(define-foreign (gtk-text-buffer-create-mark gtktextbuffer* (maybe string) gtktextiter* bool) gtktextmark*)
(define-foreign (gtk-text-buffer-move-mark gtktextbuffer* gtktextmark* gtktextiter*) void)
(define-foreign (gtk-text-buffer-delete-mark gtktextbuffer* gtktextmark*) void)
(define-foreign (gtk-text-buffer-get-mark gtktextbuffer* string) (maybe gtktextmark*))
(define-foreign (gtk-text-buffer-move-mark-by-name gtktextbuffer* string gtktextiter*) void)
(define-foreign (gtk-text-buffer-delete-mark-by-name gtktextbuffer* string) void)
(define-foreign (gtk-text-buffer-get-insert gtktextbuffer*) gtktextmark*)
(define-foreign (gtk-text-buffer-get-selection-bound gtktextbuffer*) gtktextmark*)
(define-foreign (gtk-text-buffer-place-cursor gtktextbuffer* gtktextiter*) void)
(define-foreign (gtk-text-buffer-select-range gtktextbuffer* gtktextiter* gtktextiter*) void)
(define-foreign (gtk-text-buffer-apply-tag gtktextbuffer* gtktexttag* gtktextiter* gtktextiter*) void)
(define-foreign (gtk-text-buffer-remove-tag gtktextbuffer* gtktexttag* gtktextiter* gtktextiter*) void)
(define-foreign (gtk-text-buffer-apply-tag-by-name gtktextbuffer* string gtktextiter* gtktextiter*) void)
(define-foreign (gtk-text-buffer-remove-tag-by-name gtktextbuffer* string gtktextiter* gtktextiter*) void)
(define-foreign (gtk-text-buffer-remove-all-tags gtktextbuffer* gtktextiter* gtktextiter*) void)
;; Again, var args are not yet supported in define-foreign.
;; (But then again, why not support them?)
;(define-foreign (gtk-text-buffer-create-tag gtktextbuffer* string string ...) gtktexttag*)
(define-foreign (gtk-text-buffer-get-iter-at-line-offset gtktextbuffer* gtktextiter* int int) void)
(define-foreign (gtk-text-buffer-get-iter-at-line-index gtktextbuffer* gtktextiter* int int) void)
(define-foreign (gtk-text-buffer-get-iter-at-offset gtktextbuffer* gtktextiter* int) void)
(define-foreign (gtk-text-buffer-get-iter-at-line gtktextbuffer* gtktextiter* int) void)
(define-foreign (gtk-text-buffer-get-start-iter gtktextbuffer* gtktextiter*) void)
(define-foreign (gtk-text-buffer-get-end-iter gtktextbuffer* gtktextiter*) void)
(define-foreign (gtk-text-buffer-get-bounds gtktextbuffer* gtktextiter* gtktextiter*) void)
(define-foreign (gtk-text-buffer-get-iter-at-mark gtktextbuffer* gtktextiter* gtktextmark*) void)
(define-foreign (gtk-text-buffer-get-iter-at-child-anchor gtktextbuffer* gtktextiter* gtktextchildanchor*) void)
(define-foreign (gtk-text-buffer-get-modified gtktextbuffer*) bool)
(define-foreign (gtk-text-buffer-set-modified gtktextbuffer* bool) void)
(define-foreign (gtk-text-buffer-add-selection-clipboard gtktextbuffer* gtkclipboard*) void)
(define-foreign (gtk-text-buffer-remove-selection-clipboard gtktextbuffer* gtkclipboard*) void)
(define-foreign (gtk-text-buffer-cut-clipboard gtktextbuffer* gtkclipboard* bool) void)
(define-foreign (gtk-text-buffer-copy-clipboard gtktextbuffer* gtkclipboard*) void)
(define-foreign (gtk-text-buffer-paste-clipboard gtktextbuffer* gtkclipboard* (maybe gtktextiter*) bool) void)
(define-foreign (gtk-text-buffer-get-selection-bounds gtktextbuffer* gtktextiter* gtktextiter*) bool)
(define-foreign (gtk-text-buffer-delete-selection gtktextbuffer* bool bool) bool)
(define-foreign (gtk-text-buffer-begin-user-action gtktextbuffer*) void)
(define-foreign (gtk-text-buffer-end-user-action gtktextbuffer*) void)

(define-foreign (gtk-text-iter-get-buffer gtktextiter*) gtktextbuffer*)
(define-foreign (gtk-text-iter-copy gtktextiter*) gtktextiter*)
(define-foreign (gtk-text-iter-free gtktextiter*) void)
(define-foreign (gtk-text-iter-get-offset gtktextiter*) int)
(define-foreign (gtk-text-iter-get-line gtktextiter*) int)
(define-foreign (gtk-text-iter-get-line-offset gtktextiter*) int)
(define-foreign (gtk-text-iter-get-line-index gtktextiter*) int)
(define-foreign (gtk-text-iter-get-visible-line-offset gtktextiter*) int)
(define-foreign (gtk-text-iter-get-visible-line-index gtktextiter*) int)
(define-foreign (gtk-text-iter-get-char gtktextiter*) uint) ;; gunichar is guint32...
(define-foreign (gtk-text-iter-get-slice gtktextiter* gtktextiter*) string)
(define-foreign (gtk-text-iter-get-text   gtktextiter* gtktextiter*) string)
(define-foreign (gtk-text-iter-get-visible-slice gtktextiter* gtktextiter*) string)
(define-foreign (gtk-text-iter-get-visible-text  gtktextiter* gtktextiter*) string)
(define-foreign (gtk-text-iter-get-child-anchor gtktextiter*) gtktextchildanchor*)
(define-foreign (gtk-text-iter-get-toggled-tags gtktextiter* bool) gslist*)
(define-foreign (gtk-text-iter-begins-tag gtktextiter* gtktexttag*) bool)
(define-foreign (gtk-text-iter-ends-tag gtktextiter* gtktexttag*) bool)
(define-foreign (gtk-text-iter-toggles-tag gtktextiter* gtktexttag*) bool)
(define-foreign (gtk-text-iter-has-tag gtktextiter* gtktexttag*) bool)
(define-foreign (gtk-text-iter-get-tags gtktextiter*) gslist*)
(define-foreign (gtk-text-iter-editable gtktextiter* bool) bool)
(define-foreign (gtk-text-iter-can-insert gtktextiter* bool) bool)
(define-foreign (gtk-text-iter-starts-word gtktextiter*) bool)
(define-foreign (gtk-text-iter-ends-word gtktextiter*) bool)
(define-foreign (gtk-text-iter-inside-word gtktextiter*) bool)
(define-foreign (gtk-text-iter-starts-sentence gtktextiter*) bool)
(define-foreign (gtk-text-iter-ends-sentence gtktextiter*) bool)
(define-foreign (gtk-text-iter-inside-sentence gtktextiter*) bool)
(define-foreign (gtk-text-iter-starts-line gtktextiter*) bool)
(define-foreign (gtk-text-iter-ends-line gtktextiter*) bool)
(define-foreign (gtk-text-iter-is-cursor-position gtktextiter*) bool)
(define-foreign (gtk-text-iter-get-chars-in-line gtktextiter*) int)
(define-foreign (gtk-text-iter-get-bytes-in-line gtktextiter*) int)
;(define-foreign (gtk-text-iter-get-attributes gtktextiter* gtktextattributes*) bool)
;(define-foreign (gtk-text-iter-get-language gtktextiter*) pangolanguage*)
(define-foreign (gtk-text-iter-is-end gtktextiter*) bool)
(define-foreign (gtk-text-iter-is-start gtktextiter*) bool)

(define-foreign (gtk-text-iter-forward-char gtktextiter*) bool)
(define-foreign (gtk-text-iter-backward-char gtktextiter*) bool)
(define-foreign (gtk-text-iter-forward-chars gtktextiter* int) bool)
(define-foreign (gtk-text-iter-backward-chars gtktextiter* int) bool)
(define-foreign (gtk-text-iter-forward-line gtktextiter*) bool)
(define-foreign (gtk-text-iter-backward-line gtktextiter*) bool)
(define-foreign (gtk-text-iter-forward-lines gtktextiter* int) bool)
(define-foreign (gtk-text-iter-backward-lines gtktextiter* int) bool)
(define-foreign (gtk-text-iter-forward-word-end gtktextiter*) bool)
(define-foreign (gtk-text-iter-backward-word-start gtktextiter*) bool)
(define-foreign (gtk-text-iter-forward-word-ends gtktextiter* int) bool)
(define-foreign (gtk-text-iter-backward-word-starts gtktextiter* int) bool)
(define-foreign (gtk-text-iter-forward-visible-word-end gtktextiter*) bool)
(define-foreign (gtk-text-iter-backward-visible-word-start gtktextiter*) bool)
(define-foreign (gtk-text-iter-forward-visible-word-ends gtktextiter* int) bool)
(define-foreign (gtk-text-iter-backward-visible-word-starts gtktextiter* int) bool)
(define-foreign (gtk-text-iter-forward-cursor-position gtktextiter*) bool)
(define-foreign (gtk-text-iter-backward-cursor-position gtktextiter*) bool)
(define-foreign (gtk-text-iter-forward-cursor-positions gtktextiter* int) bool)
(define-foreign (gtk-text-iter-backward-cursor-positions gtktextiter* int) bool)
(define-foreign (gtk-text-iter-forward-visible-cursor-position gtktextiter*) bool)
(define-foreign (gtk-text-iter-backward-visible-cursor-position gtktextiter*) bool)
(define-foreign (gtk-text-iter-forward-visible-cursor-positions gtktextiter* int) bool)
(define-foreign (gtk-text-iter-backward-visible-cursor-positions gtktextiter* int) bool)

(define-foreign (gtk-text-iter-set-offset gtktextiter* int) void)
(define-foreign (gtk-text-iter-set-line gtktextiter* int) void)
(define-foreign (gtk-text-iter-set-line-offset gtktextiter* int) void)
(define-foreign (gtk-text-iter-set-line-index gtktextiter* int) void)
(define-foreign (gtk-text-iter-forward-to-end gtktextiter*) void)
(define-foreign (gtk-text-iter-forward-to-line-end gtktextiter*) void)
(define-foreign (gtk-text-iter-set-visible-line-offset gtktextiter* int) void)
(define-foreign (gtk-text-iter-set-visible-line-index gtktextiter* int) void)

(define-foreign (gtk-text-iter-forward-to-tag-toggle gtktextiter* gtktexttag*) bool)
(define-foreign (gtk-text-iter-backward-to-tag-toggle gtktextiter* gtktexttag*) bool)
(define-foreign (gtk-text-iter-forward-find-char gtktextiter* (-> (uint void*) bool) void* gtktextiter*) bool)
(define-foreign (gtk-text-iter-backward-find-char gtktextiter* (-> (uint void*) bool) void* gtktextiter*) bool)
;; FSK is too lazy to add the gtktextsearchflags enum
;(define-foreign (gtk-text-iter-forward-search gtktextiter* string gtktextsearchflags gtktextiter* gtktextiter* gtktextiter*) bool)
;(define-foreign (gtk-text-iter-backward-search gtktextiter* string gtktextsearchflags gtktextiter* gtktextiter* gtktextiter*) bool)
(define-foreign (gtk-text-iter-equal gtktextiter* gtktextiter*) bool)
(define-foreign (gtk-text-iter-compare gtktextiter* gtktextiter*) bool)
(define-foreign (gtk-text-iter-in-range gtktextiter* gtktextiter* gtktextiter*) bool)
(define-foreign (gtk-text-iter-order gtktextiter* gtktextiter*) void)

(define-foreign (gtk-clipboard-get gdkatom*) gtkclipboard*)
; FSK is too lazy to add gdkdisplay* now
;(define-foreign (gtk-clipboard-get-for-display gdkdisplay* gdkatom*) gtkclipboard*)
;(define-foreign (gtk-clipboard-get-display gtkclipboard*) gdkdisplay*)
(define-foreign (gtk-clipboard-set-text gtkclipboard* string int) void)
(define-foreign (gtk-clipboard-set-image gtkclipboard* gdkpixbuf*) void)

(define-foreign (gtk-dialog-new) gtkdialog*)
(define-syntax define-cfields-offsets/target-dep-paths
  (syntax-rules ()
    ((_ (HEADERS ...) FORMS ...)
     (cond-expand
      (macosx 
       (define-c-info
         (path "/sw/include/gtk-2.0")
         (path "/sw/include/glib-2.0") 
         (path "/sw/lib/glib-2.0/include")
         (path "/sw/lib/gtk-2.0/include")
         (path "/sw/include/pango-1.0")
         (path "/sw/include/atk-1.0")
         (path "/sw/include/gtk-2.0")
         (include<> HEADERS) ... FORMS ...))
      (unix
       (define-c-info
         (path "/usr/include/glib-2.0") 
         (path "/usr/lib/glib-2.0/include")
         (path "/usr/lib/gtk-2.0/include") 
         (path "/usr/include/pango-1.0")
         (path "/usr/include/cairo")
         (path "/usr/include/atk-1.0") 
         (path "/usr/include/gtk-2.0")
         (include HEADERS) ... FORMS ...))
      (else
       (error 'define-cfields-offsets ": no support for your target..."))))))

(define-cfields-offsets/target-dep-paths ("gtk/gtk.h") 
  (fields "GtkObject" (gtkobject-flags-offset "flags"))
  (fields "GtkDialog" 
          (gtkdialog-vbox-offset "vbox")
          (gtkdialog-action-area-offset "action_area"))
  (fields "GtkFileSelection" 
          (gtkfilesel-dir-list-offset "dir_list")
          (gtkfilesel-file-list-offset "file_list")
          (gtkfilesel-selection-entry-offset "selection_entry")
          (gtkfilesel-selection-text-offset "selection_text")
          (gtkfilesel-main-vbox-offset "main_vbox")
          (gtkfilesel-ok-button-offset "ok_button")
          (gtkfilesel-cancel-button-offset "cancel_button")
          (gtkfilesel-help-button-offset "help_button")
          (gtkfilesel-history-pulldown-offset "history_pulldown")
          (gtkfilesel-history-menu-offset "history_menu")
          (gtkfilesel-history-list-offset "history_list"))
;; Deprecated in gtk2
;  (fields "GtkText" 
;          (gtktext-text-area-offset "text_area")
;          (gtktext-hadj-offset      "hadj")
;          (gtktext-vadj-offset      "vadj"))
  (fields "GtkTextView"
          (layout-offset "layout")
          (buffer-offset "buffer")
          (text-window-offset "text_window")
          (left-window-offset "left_window")
          (right-window-offset "right_window")
          (top-window-offset "top_window")
          (bottom-window-offset "bottom_window")
          (hadjustment-offset "hadjustment")
          (vadjustment-offset "vadjustment")
          )
  (sizeof sizeof-gtktextiter "GtkTextIter")
  )

(define malloc-gtk-text-iter
  (let ((malloc (stdlib/malloc gtktextiter*-rt)) ; potential space leak!
        (size sizeof-gtktextiter))
    (lambda ()
      (malloc size))))

(define (gtk-text-view-hadjustment text-view)
  (void*-void*-ref text-view hadjustment-offset))
(define (gtk-text-view-vadjustment text-view)
  (void*-void*-ref text-view vadjustment-offset))

(define (gtk-dialog-vbox dialog)
  (void*-void*-ref dialog gtkdialog-vbox-offset))
(define (gtk-dialog-action-area dialog)
  (void*-void*-ref dialog gtkdialog-action-area-offset))

(define-foreign (gtk-file-selection-new string) gtkfileselection*)
(define-foreign (gtk-file-selection-set-filename gtkfileselection* string) void)
(define-foreign (gtk-file-selection-get-filename gtkfileselection*) string)
(define-foreign (gtk-file-selection-complete gtkfileselection* string) void)
(define-foreign (gtk-file-selection-show-fileop-buttons gtkfileselection*) void)
(define-foreign (gtk-file-selection-hide-fileop-buttons gtkfileselection*) void)
;; XXX add support for gtk_file_selection_get_selections
(define-foreign (gtk-file-selection-set-select-multiple gtkfileselection* bool) void)
(define-foreign (gtk-file-selection-get-select-multiple gtkfileselection*) bool)

(define (gtk-file-selection-ok-button filesel)
  (void*-void*-ref filesel gtkfilesel-ok-button-offset))
(define (gtk-file-selection-cancel-button filesel)
  (void*-void*-ref filesel gtkfilesel-cancel-button-offset))

(define GTK-WINDOW-TOPLEVEL 0)

(define GTK-EXPAND 1)
(define GTK-SHRINK 2)
(define GTK-FILL   4)

(define GTK-UPDATE-CONTINUOUS 0)
(define GTK-UPDATE-DISCONTINUOUS 1)
(define GTK-UPDATE-DELAYED 0)

(define GTK-POS-LEFT 0)
(define GTK-POS-RIGHT 1)
(define GTK-POS-TOP 2)
(define GTK-POS-BOTTOM 3)

(define GTK-JUSTIFY-LEFT 0)
(define GTK-JUSTIFY-RIGHT 1)
(define GTK-JUSTIFY-CENTER 2)
(define GTK-JUSTIFY-FILL 3)

(define GTK-ARROW-UP 0)
(define GTK-ARROW-DOWN 1)
(define GTK-ARROW-LEFT 2)
(define GTK-ARROW-RIGHT 3)

(define GTK-SHADOW-NONE 0)
(define GTK-SHADOW-IN 1)
(define GTK-SHADOW-OUT 2)
(define GTK-SHADOW-ETCHED-IN 3)
(define GTK-SHADOW-ETCHED-OUT 4)

(define GTK-PROGRESS-LEFT-TO-RIGHT 0)
(define GTK-PROGRESS-RIGHT-TO-LEFT 1)
(define GTK-PROGRESS-BOTTOM-TO-TOP 2)
(define GTK-PROGRESS-TOP-TO-BOTTOM 3)

(define GTK-ACCEL-VISIBLE #b01)
(define GTK-ACCEL-LOCKED  #b10)
(define GTK-ACCEL-MASK    #x07)

(define GTK-ORIENTATION-HORIZONTAL 0)
(define GTK-ORIENTATION-VERTICAL 1)

(define GTK-TOOLBAR-ICONS 0)
(define GTK-TOOLBAR-TEXT  1)
(define GTK-TOOLBAR-BOTH  2)
(define GTK-TOOLBAR-BOTH-HORIZ 3)

(define GTK-TOPLEVEL    (fxlsh 1 4))
(define GTK-NO-WINDOW   (fxlsh 1 5))
(define GTK-REALIZED    (fxlsh 1 6))
(define GTK-MAPPED      (fxlsh 1 7))
(define GTK-VISIBLE     (fxlsh 1 8))
(define GTK-SENSITIVE   (fxlsh 1 9))
(define GTK-PARENT-SENSITIVE (fxlsh 1 10))
(define GTK-CAN-FOCUS   (fxlsh 1 11))
(define GTK-HAS-FOCUS   (fxlsh 1 12))
(define GTK-CAN-DEFAULT (fxlsh 1 13))
(define GTK-HAS-DEFAULT (fxlsh 1 14))
(define GTK-HAS-GRAB    (fxlsh 1 15))
(define GTK-RC-STYLE    (fxlsh 1 16))
(define GTK-COMPOSITE-CHILD (fxlsh 1 17))
(define GTK-NO-REPARENT (fxlsh 1 18))
(define GTK-APP-PAINTABLE (fxlsh 1 19))
(define GTK-RECEIVES_DEFAULT (fxlsh 1 20))
(define GTK-DOUBLE-BUFFERED (fxlsh 1 21))
(define GTK-NO-SHOW-ALL     (fxlsh 1 22))

;; BELOW ARE DEPRECATED ACCORDING TO GTK+ HEADER FILES...
(define GTK-TOOLBAR-CHILD-SPACE 0)
(define GTK-TOOLBAR-CHILD-BUTTON 1)
(define GTK-TOOLBAR-CHILD-TOGGLEBUTTON 2)
(define GTK-TOOLBAR-CHILD-RADIOBUTTON 3)
(define GTK-TOOLBAR-CHILD-WIDGET 4)
