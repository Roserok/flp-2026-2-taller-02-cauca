#lang eopl
;Autores: Nombre1 Codigo1, Nombre2 Codigo2

;; Taller 2 — El intérprete de Cauca.
;; Especificación léxica, especificación gramatical, scanner y parser.
;; Este módulo no requiere ningún otro.
;;
;; Lo que se escribe aquí:
;;
;;   especificacion-lexica      comentarios que empiezan con //, espacios
;;                              en blanco, números enteros y flotantes con
;;                              signo, e identificadores que empiezan por
;;                              letra y siguen con letras, dígitos, guion
;;                              bajo o signo de interrogación
;;   especificacion-gramatical  las producciones de <programa>,
;;                              <expresion> y <primitiva>, con los nombres
;;                              de constructor que indican los recuadros
;;                              del enunciado
;;   scanner : string -> lista de tokens   se construye con
;;                                         sllgen:make-string-scanner
;;   parser  : string -> programa          se construye con
;;                                         sllgen:make-string-parser
;;
;; La llamada a sllgen:make-define-datatypes genera los datatypes
;; programa, expresion y primitiva a partir de la gramática, con sus
;; constructores y sus predicados. Mientras la gramática esté vacía no
;; genera ninguno.

;; especificacion lexica
;; Lista de reglas léxicas de Cauca
;;  Los espacios en blanco y los comentarios (// hasta fin de línea) se ignoran
;;   identificador: letra seguida de letras, dígitos, "_" o "?"
;;  numero: entero o flotante, positivo o negativo

(define especificacion-lexica
  '((espacio-blanco (whitespace) skip)
    (comentario ("//" (arbno (not #\newline))) skip)
    (identificador (letter (arbno (or letter digit "_" "?"))) symbol)
    (numero (digit (arbno digit)) number)
    (numero ("-" digit (arbno digit)) number)
    (numero (digit (arbno digit) "." digit (arbno digit)) number)
    (numero ("-" digit (arbno digit) "." digit (arbno digit)) number)))
 
;; especificacion-gramatical
;; Gramática completa de Cauca (Partes 1 a 4). Los nombres de los
;; constructores son los que pide el enunciado.
;; Nota: el enunciado pide {"of" <numero> "=>" <expresion>}+ en case, pero
;; SLLGEN solo ofrece arbno (cero o más). La exigencia de al menos una rama
;; no se puede expresar en la gramática sin cambiar los campos de case-exp.
(define especificacion-gramatical
  '((programa (expresion) a-program)
 
    ;; Parte 1: base
    (expresion (numero) lit-exp)
    (expresion (identificador) var-exp)
    (expresion ("true") true-exp)
    (expresion ("false") false-exp)
    (expresion (primitiva "(" (separated-list expresion ",") ")") prim-exp)
    (expresion ("if" expresion "then" expresion "else" expresion "end") if-exp)
    (expresion ("let" (arbno identificador "=" expresion) "in" expresion "end")
               let-exp)
 
    ;; Parte 3: procedimientos 
    (expresion ("proc" "(" (separated-list identificador ",") ")" expresion "end")
               proc-exp)
    (expresion ("apply" expresion "(" (separated-list expresion ",") ")")
               app-exp)
 
    ;; Parte 4: recursión y selección por valor
    (expresion ("letrec"
                (arbno identificador "(" (separated-list identificador ",") ")"
                       "=" expresion)
                "in" expresion "end")
               letrec-exp)
    (expresion ("case" expresion
                (arbno "of" numero "=>" expresion)
                "otherwise" "=>" expresion "end")
               case-exp)
 
    ;; Primitivas base
    (primitiva ("+") sum-prim)
    (primitiva ("-") minus-prim)
    (primitiva ("*") mult-prim)
    (primitiva ("/") div-prim)
    (primitiva ("add1") add-prim)
    (primitiva ("sub1") sub-prim)
    (primitiva (">") mayor-prim)
    (primitiva (">=") mayorigual-prim)
    (primitiva ("<") menor-prim)
    (primitiva ("<=") menorigual-prim)
    (primitiva ("==") igual-prim)
    (primitiva ("not") not-prim)
    (primitiva ("and") and-prim)
    (primitiva ("or") or-prim)
 
    ;; Parte 2: primitivas nuevas
    (primitiva ("abs") abs-prim)
    (primitiva ("mcd") mcd-prim)
    (primitiva ("mcm") mcm-prim)
    (primitiva ("promedio") promedio-prim)
    (primitiva ("xor") xor-prim)
    (primitiva ("implica") implica-prim)
    (primitiva ("entre") entre-prim)))
 
(sllgen:make-define-datatypes especificacion-lexica especificacion-gramatical)

;; mostrar-datatypes : -> void
;; Lista en pantalla los datatypes que SLLGEN genera a partir de la
;; gramática. Sirve para revisar los nombres de los constructores.
(define mostrar-datatypes
  (lambda ()
    (sllgen:list-define-datatypes especificacion-lexica especificacion-gramatical)))

;; scanner : string -> lista de tokens
;; Convierte el texto de un programa en la lista de sus tokens.
(define scanner
    (sllgen:make-string-scanner especificacion-lexica especificacion-gramatical))

;; parser : string -> programa
;; Convierte el texto de un programa en su árbol de sintaxis abstracta.
(define parser
  (sllgen:make-string-scanner especificacion-lexica especificacion-gramatical))

(provide (all-defined-out))
