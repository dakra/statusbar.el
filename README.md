# Emacs statusbar

Show a statusbar on the bottom right corner over the minibuffer area.

You can pull mode-line variables to be shown in the statusbar
instead of the mode-line, display your own variables or show custom
string.

If you use Emacs full-screen and have the frame split into multiple
windows (or even use Emacs as your window manager with Exwm),
the mode-line often shows information that's not specific to a
certain window/buffer but yet are repeated every window and clutter
the mode-line. E.g. `org-mode-line-string`, `display-time-string`,
or `battery-mode-line-string` are such candidates.

`statusbar` removes them from your mode-line and only shows
them once on the bottom-right over the minibuffer, which
is most of the time empty anyway.


## Configuration

See the `statusbar` customization group for settings:
`M-x customize-group RET statusbar`


## Usage

`statusbar` defines a global minor mode and can be turned on and off
with `statusbar-mode`.


## Warning

This package is alpha and you certainly will find bugs.
Please report issues [on GitHub](https://github.com/dakra/statusbar.el/issues).
