#!/bin/sed -urf
# -*- coding: UTF-8, tab-width: 2 -*-

# Case-insensitive keywords
s~$\
  |bielefel[dt]|$\
  |erlang_cookie|$\
  |sw[o0]rd[_ -]*fish|$\
  ~\a&\v~ig


# Case-sensitive keywords
s~$\
  |\b(benn?iGN)($|[^a-z])|$\
  ~\a&\v~g


# Slack API Tokens:
s~/services/T[A-Za-z0-9]{5,}/B[A-Za-z0-9]{5,}/[A-Za-z0-9]{5,}~\a&\v~ig




/^\f<path>/{
  s~$\
    |\.pem|$\
    |token|$\
    ~\a&\v~ig
  s~(/dummy)\a(\.pem)\v$~\1\2~
}












: end
