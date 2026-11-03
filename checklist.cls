\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{checklist}[2026/11/03 Two-column checklist pages]

% Options: letterpaper (default), a4paper, landscape, portrait (default)
\newif\ifchecklist@landscape
\DeclareOption{landscape}{\checklist@landscapetrue}
\DeclareOption{portrait}{\checklist@landscapefalse}
\DeclareOption{letterpaper}{\def\checklist@paper{letterpaper}}
\DeclareOption{a4paper}{\def\checklist@paper{a4paper}}
\def\checklist@paper{letterpaper}
\ProcessOptions\relax

\LoadClass[10pt]{article}

\RequirePackage[\checklist@paper,\ifchecklist@landscape landscape,\fi
                margin=0.5in,top=0.9in,bottom=0.7in]{geometry}
\RequirePackage{multicol}
\RequirePackage{amssymb}      % \square
\RequirePackage{xcolor}
\RequirePackage{fancyhdr}
\RequirePackage{needspace}
\RequirePackage{etoolbox}

\renewcommand{\familydefault}{\sfdefault}
\setlength{\parindent}{0pt}
\setlength{\columnsep}{0.4in}
\setlength{\columnseprule}{0.4pt}
\definecolor{checkrule}{gray}{0.55}
\definecolor{sectionbg}{gray}{0.88}

% ---- Metadata ------------------------------------------------------------
\newcommand{\checklistsubtitle}[1]{\gdef\checklist@subtitle{#1}}
\newcommand{\checklistrevision}[1]{\gdef\checklist@revision{#1}}
\gdef\checklist@subtitle{}
\gdef\checklist@revision{}
% \title{...} is the checklist title (standard LaTeX macro)

% ---- Running header / footer --------------------------------------------
\pagestyle{fancy}
\fancyhf{}
\renewcommand{\headrulewidth}{0.6pt}
\renewcommand{\footrulewidth}{0pt}
\fancyhead[L]{\bfseries\large\@title}
\fancyhead[R]{\ifdefempty{\checklist@subtitle}{}{\checklist@subtitle}}
\fancyfoot[L]{\footnotesize\ifdefempty{\checklist@revision}{}{\checklist@revision}}
\fancyfoot[R]{\footnotesize Page \thepage}
\setlength{\headheight}{16pt}

% ---- The checklist body --------------------------------------------------
% Everything between \begin{checklist} and \end{checklist} flows into two
% columns, balanced on the last page, using \checksection / \checkitem / ...
\newenvironment{checklist}
  {\begin{multicols}{2}\raggedcolumns}
  {\end{multicols}}

\newlength{\checkboxwidth}
\setlength{\checkboxwidth}{1.5em}

% \checksection{Name}: shaded heading bar, kept with the next few items
\newcommand{\checksection}[1]{%
  \par\Needspace{4\baselineskip}%
  \vspace{0.6\baselineskip}%
  \noindent\colorbox{sectionbg}{\parbox{\dimexpr\linewidth-2\fboxsep\relax}{%
    \bfseries\MakeUppercase{#1}}}\par
  \vspace{0.25\baselineskip}}

% \checkitem{challenge}{response}: box, challenge, dot leader, response.
% An empty response gives a plain checkbox line with no leader.
\newcommand{\checkitem}[2]{%
  \par\noindent\hangindent=\checkboxwidth\hangafter=1
  \makebox[\checkboxwidth][l]{$\square$}#1%
  \ifblank{#2}{}{\nobreak\hskip 0.4em\leaders\hbox to 0.5em{\hss.\hss}\hfill
    \hskip 0.4em\textbf{#2}}%
  \par\vspace{0.35\baselineskip}}

% \checknote{text}: indented italic note, no checkbox
\newcommand{\checknote}[1]{%
  \par\noindent\hangindent=\checkboxwidth\hangafter=0
  \hspace*{\checkboxwidth}\textit{#1}\par\vspace{0.35\baselineskip}}

% \checkcolumnbreak / \checkpagebreak: explicit layout control
\newcommand{\checkcolumnbreak}{\columnbreak}
\newcommand{\checkpagebreak}{\end{multicols}\newpage\begin{multicols}{2}\raggedcolumns}

\endinput
