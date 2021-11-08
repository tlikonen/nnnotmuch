NNNotmuch
=========

**[Notmuch][] search engine back-end for [Gnus][] ([Emacs's][Emacs] mail
and news client)**


Info
----

With this back-end you can create virtual Notmuch-based message groups
in Gnus. Groups' messages are dynamically generated every time through
preconfigured Notmuch search terms. For example, you can have a group
like

    nnnotmuch:work.recent

which is configured to represent Notmuch search terms like

    date:7days.. ( to:me@work or from:me@work )

When you enter the group you will get a list of messages (summary
buffer) resulting from the configured Notmuch search.

[Notmuch]: https://notmuchmail.org/
[Gnus]: http://www.gnus.org/
[Emacs]: https://www.gnu.org/software/emacs/


Installation and Usage
----------------------

Evaluate the `nnnotmuch.el` code at Gnus startup (e.g., `(require
'nnnotmuch)`). Add *nnnotmuch* server and group configuration in Gnus's
startup file.

The nnnotmuch server name is the filename of Notmuch configuration file.
The server name is passed to Notmuch executable program with `--config=`
option. If the server name is the empty string `""` (nameless server)
then the default Notmuch configuration file is used.

For example:

    (push '(nnnotmuch "") gnus-secondary-select-methods)
    (push '(nnnotmuch "~/.other-notmuch-config") gnus-secondary-select-methods)

    (setq nnnotmuch-groups
          '((""   ; Nameless server (the default Notmuch config)
             ("work.recent" "date:7days.." "(" "to:me@work" "or" "from:me@work" ")")
             ("work.boss" "date:1months.." "from:boss@work"))
            ("~/.other-notmuch-config"
             ("some.group.name" "search" "terms" "here")
             ("other.group.name" "other" "search" "terms"))))

    (setq nnnotmuch-program "notmuch") ; This is the default.

Group names can be any strings. This back-end relies entirely on Notmuch
to access mail files and provide content for Gnus. The above example
configuration will introduce the following groups:

    nnnotmuch:work.recent
    nnnotmuch:work.boss
    nnnotmuch+~/.other-notmuch-config:some.group.name
    nnnotmuch+~/.other-notmuch-config:other.group.name


Copyright and License
---------------------

Copyright (C) 2016-2017 Teemu Likonen <<tlikonen@iki.fi>>

PGP: [6965F03973F0D4CA22B9410F0F2CAE0E07608462][PGP]

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

The license text: <http://www.gnu.org/licenses/gpl-3.0.html>

[PGP]: http://www.iki.fi/tlikonen/pgp-key.asc
