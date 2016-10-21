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


Installation
------------

Evaluate the code at Gnus startup (e.g., `(require 'nnnotmuch)`). Add
*nnnotmuch* server and group configuration in Gnus's startup file. For
example:

    (push '(nnnotmuch "server") gnus-secondary-select-methods)
    (push '(nnnotmuch "") gnus-secondary-select-methods)

    (setq nnnotmuch-groups
          '(("server"
             ("some.group.name" "search" "terms" "here"))
             ("other.group.name" "other" "search" "terms"))
            ("" ; A nameless server.
             ("work.recent" "date:7days.." "(" "to:me@work" "or" "from:me@work" ")")
             ("work.boss" "date:1months.." "from:boss@work"))))

    (setq nnnotmuch-program "notmuch") ; This is the default.

Server names and group names can be any strings. This back-end relies
entirely on Notmuch to access files and provide content. The example
configuration will introduce the following groups:

    nnnotmuch+server:some.group.name
    nnnotmuch+server:other.group.name
    nnnotmuch:work.recent
    nnnotmuch:work.boss


Copyright and License
---------------------

Copyright (C) 2016 Teemu Likonen <<tlikonen@iki.fi>>

PGP: [4E10 55DC 84E9 DFF6 13D7 8557 719D 69D3 2453 9450][PGP]

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
Public License for more details.

The license text: <http://www.gnu.org/licenses/gpl-3.0.html>

[PGP]: http://koti.kapsi.fi/~dtw/pgp-key.asc
