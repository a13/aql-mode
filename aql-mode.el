;;; aql-mode.el --- Major mode for editing AQL files -*- lexical-binding: t -*-

;; Copyright (C) 2016, by Matthew R. Silver

;; Author: Matthew Silver (msilver@vectranetworks.com)
;; Homepage: https://github.com/matthewrsilver/aql-mode
;; Package-Requires: ((emacs "24"))
;; Version: 0.3
;; Created: July 26, 2016
;; License: MIT License -- see LICENSE.txt

;;; Commentary:
;; major mode for Arango Query Language (AQL) syntax highlighting and indentation

;;; Code:

(defgroup aql nil
  "Major mode for editing AQL files."
  :group 'languages)

;; Hook for user to perform tasks at the time this mode is loaded
;;;###autoload
(defcustom aql-mode-hook nil
  "List of hook functions run by `aql-mode'."
  :type 'hook
  :group 'aql)

;; Indentation
;;
;; The indentation component consists of  a single function aql-indent-line that
;; is called whenever emacs needs to determine how to indent a line.

(defcustom aql-tab-width
  (cond ((boundp 'tab-width)
         tab-width)
        ;; For compatibility with pre-26 Emacs
        ((boundp 'default-tab-width)
         default-tab-width)
        (t nil))
  "Tab width for aql-mode."
  :type 'integer
  :group 'aql)


;; Special keymap for aql-mode
(defvar aql-mode-map
  (let ((map (make-keymap)))
    ;; this is the default binding, just here as an example
    (define-key map "\C-j" 'newline-and-indent)
    ;; disable automatic indentation and movement of cursor on comments
    (define-key map "/" 'self-insert-command)
    (define-key map "*" 'self-insert-command)
    (define-key map ":" 'self-insert-command)
    map)
  "Keymap for AQL major mode.")

;; associate this mode with .aql files
(add-to-list 'auto-mode-alist '("\\.aql$" . aql-mode))




;; Syntax Highlighting
;;
;; This  mode inherits  from  c-mode,  which handles  the  comments and  strings
;; nicely.  The  keywords,  constants,  etc.  are all  specific  for  AQL.  Also
;; highlighted are numeric literals, and AQL's special bind variables.

(defvar aql-keywords
  '("AGGREGATE"        "ALL"              "AND"              "ANY"
    "ASC"              "COLLECT"          "DESC"             "DISTINCT"
    "FILTER"           "FOR"              "GRAPH"            "IN"
    "INBOUND"          "INSERT"           "INTO"             "LET"
    "LIMIT"            "NOT"              "OR"               "OUTBOUND"
    "REMOVE"           "REPLACE"          "RETURN"           "SHORTEST_PATH"
    "SORT"             "UPDATE"           "UPSERT"           "WITH"))

(defvar aql-constants
  '("FALSE"            "NONE"             "NULL"             "TRUE"
    "NEW"              "OLD"))

(defvar aql-builtins
  '("TO_BOOL"          "TO_NUMBER"        "TO_STRING"        "TO_ARRAY"
    "TO_LIST"          "IS_NULL"          "IS_BOOL"          "IS_NUMBER"
    "IS_STRING"        "IS_ARRAY"         "IS_LIST"          "IS_OBJECT"
    "IS_DOCUMENT"      "IS_DATESTRING"    "TYPENAME"

    "CHAR_LENGTH"      "CONCAT"           "CONCAT_SEPARATOR" "CONTAINS"
    "COUNT"            "FIND_FIRST"       "FIND_LAST"        "LEFT"
    "LENGTH"           "LIKE"             "LOWER"            "LTRIM"
    "MD5"              "RANDOM_TOKEN"     "REGEX_TEST"       "REVERSE"
    "RIGHT"            "RTRIM"            "SHA1"             "SPLIT"
    "SUBSTITUTE"       "SUBSTRING"        "TRIM"             "UPPER"

    "ABS"              "ACOS"             "ASIN"             "ATAN"
    "ATAN2"            "AVERAGE"          "CEIL"             "COS"
    "DEGREES"          "EXP"              "EXP2"             "FLOOR"
    "LOG"              "LOG2"             "LOG10"            "MAX"
    "MEDIAN"           "MIN"              "PERCENTILE"       "PI"
    "POW"              "RADIANS"          "RAND"             "RANGE"
    "ROUND"            "SIN"              "SQRT"             "STDEV_POPULATION"
    "STDEV_SAMPLE"     "SUM"              "TAN"              "VARIANCE_POPULATION"
    "VARIANCE_SAMPLE"

    "DATE_NOW"         "DATE_TIMESTAMP"   "DATE_ISO8601"     "DATE_DAYOFWEEK"
    "DATE YEAR"        "DATE_MONTH"       "DATE_DAY"         "DATE_HOUR"
    "DATE_MINUTE"      "DATE_SECOND"      "DATE_MILLISECOND" "DATE_DAYOFYEAR"
    "DATE_ISOWEEK"     "DATE_LEAPYEAR"    "DATE_QUARTER"     "DATE_DAYS_IN_MONTH"
    "DATE_FORMAT"      "DATE_ADD"         "DATE_SUBTRACT"    "DATE_DIFF"
    "DATE_COMPARE"

    "APPEND"           "COUNT"            "FIRST"            "FLATTEN"
    "INTERSECTION"     "MINUS"            "NTH"              "POP"
    "POSITION"         "PUSH"             "REMOVE_NTH"       "REMOVE_VALUE"
    "REMOVE_VALUES"    "REVERSE"          "SHIFT"            "SLICE"
    "UNION"            "UNION_DISTICT"    "UNIQUE"           "UNSHIFT"

    "ATTRIBUTES"       "HAS"              "KEEP"             "IS_SAME_COLLECTION"
    "MATCHES"          "MERGE"            "MERGE_RECURSIVE"  "PARSE_IDENTIFIER"
    "TRANSLATE"        "UNSET"            "UNSET_RECURSIVE"  "VALUES"
    "ZIP"

    "NEAR"             "WITHIN"           "WITHIN_RECTANGLE" "IS_IN_POLYGON"

    "FULLTEXT"         "NOT_NULL"         "FIRST_LIST"       "FIRST_DOCUMENT"
    "COLLECTION_COUNT" "COLLECTIONS"      "CURRENT_USER"     "DOCUMENT"
    "APPLY"            "CALL"             "FAIL"             "NOOPT"
    "PASSTHRU"         "SLEEP"            "V8"))



;; generate regex strings for each category
(defvar aql-keywords-regexp (regexp-opt aql-keywords 'words))
(defvar aql-constants-regexp (regexp-opt aql-constants 'words))
(defvar aql-builtins-regexp (regexp-opt aql-builtins 'words))
(defvar aql-numeric-regexp "[-+]?\\.?\\_<[0-9]*\\.?[0-9]+\\.?\\(?:[eE][-+]?[0-9]+\\)?\\_>\\.?")
(defvar aql-bindvar-regexp "\\(^\\|[ \t]\\)@@?[a-zA-z_]+")
(defvar aql-namespace-regexp "\\([_a-zA-Z]+\\)::")

;; utility regexes
(defvar aql-close-brace-regexp "^[ \t]*[)}]")
(defvar aql-block-indenting-regexp "^[ \t]*\\(FOR\\|for\\|.*[({]$\\)")
(defvar aql-empty-regexp  "^[\s]*$")

;;;###autoload
(defun aql-indent-line ()
  "Indent current line as AQL code."
  (interactive)
  (beginning-of-line)
  ;; If the point is at the beginning of the buffer indent line to column 0
  (if (bobp)
      (indent-line-to 0)
    (let ((need-line t)
          (cur-indent nil))
      ;; if the  current line is only  a close brace,  then we can indent  it by
      ;; subtracting the tab-width from the indent of the previous line
      (if (looking-at aql-close-brace-regexp)
          (progn
            (save-excursion
              (forward-line -1)
              (setq cur-indent (- (current-indentation) aql-tab-width)))
            ;; rectify cur-indent
            (when (< cur-indent 0)
              (setq cur-indent 0)))
        ;; else (i.e. if the current line is not solely a close brace) move back
        ;; through the  previous lines  until a  non-empty, non-comment  line is
        ;; found, and base the current line's indentation on it
        (save-excursion
          (while need-line
            (forward-line -1)
            ;; if the line is a block-initiating line  -- e.g. it is a for loop,
            ;; or an open brace -- then  the current line should be indented one
            ;; tab-width forward
            (cond ((looking-at aql-block-indenting-regexp)
                   (progn
                     (setq cur-indent (+ (current-indentation) aql-tab-width))
                     (setq need-line nil))
                   ;; else if the line is totally empty, do nothing
                   (looking-at aql-empty-regexp)
                   (setq need-line t)
                   ;; else if the line is a comment, do nothing
                   (nth 4 (syntax-ppss))
                   (setq need-line t)
                   ;; else if this is the first line then just exit the loop
                   (bobp)
                   (setq need-line nil)
                   ;; finally, there  must be text on this line... indent the
                   ;; current line to match it!
                   t
                   (progn
                     (setq cur-indent (current-indentation))
                     (setq need-line nil)))))))

      ;; once the search for an informative line has been completed, we'll use
      ;; the value of cur-indent to actually indent the line
      (indent-line-to
       (or cur-indent 0)))))

;; Associate categories with faces
(defvar aql-font-lock-keywords
  `((,aql-keywords-regexp . font-lock-keyword-face)
    (,aql-constants-regexp . font-lock-constant-face)
    (,aql-builtins-regexp . font-lock-builtin-face)
    (,aql-numeric-regexp . font-lock-warning-face)
    (,aql-bindvar-regexp . font-lock-variable-name-face)
    ;; use "1" instead of "." to match only the text, not the "::"
    (,aql-namespace-regexp 1 font-lock-constant-face)))

;;;###autoload
(define-derived-mode aql-mode c-mode
  "AQL Mode"
  "Major mode for editing Arango Query Language (AQL)"

  (set (make-local-variable 'font-lock-defaults) '(aql-font-lock-keywords nil t))
  (set (make-local-variable 'indent-line-function) 'aql-indent-line))

;; add the mode to the features list
(provide 'aql-mode)

;;; aql-mode.el ends here
