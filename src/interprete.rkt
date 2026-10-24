#lang eopl
;Autores: Maria Fernanda Betancourt Montoya 2459510, Oliver De Jesus Arboleda Baez 2459684, Kevin Andres Rosero Romo 2459554

;; Taller 2 — El intérprete de Cauca.
;; El recorrido de la sintaxis abstracta y la aplicación de
;; procedimientos. Requiere sintaxis.rkt, valores.rkt, ambiente.rkt y
;; primitivas.rkt.
;;
;; apply-procedure vive aquí y no en valores.rkt porque llama a
;; evaluar-expresion.

(require "sintaxis.rkt")
(require "valores.rkt")
(require "ambiente.rkt")
(require "primitivas.rkt")

;; apply-procedure : procval x lista de valores -> valor
;; Verifica que la cantidad de argumentos coincida con la de parámetros
;; y evalúa el cuerpo en el ambiente de la clausura extendido con las
;; ligaduras de los parámetros, no en el ambiente de la llamada.
(define apply-procedure
  (lambda (proc args)
    (cases procval proc
      (cerradura (ids body env-definicion)
        ;; misma cantidad de parámetros y argumentos
        (if (= (length ids) (length args))
            ;; el cuerpo se evalúa en el ambiente donde se definió el proc
            (evaluar-expresion body
                               (ambiente-extendido ids args env-definicion))
            (eopl:error 'apply-procedure
                        "Cantidad de argumentos incorrecta: se esperaban ~s y llegaron ~s"
                        (length ids)
                        (length args)))))))

;; evaluar-programa : programa -> valor
;; Punto de entrada: evalúa la expresión del programa en el ambiente
;; inicial.
(define evaluar-programa
  (lambda (pgm)
    (cases programa pgm
      (a-program (exp)
        (evaluar-expresion exp (ambiente-inicial))))))

;; evaluar-rands : lista de expresiones x ambiente -> lista de valores
;; Evalúa las expresiones de izquierda a derecha en el mismo ambiente.
(define evaluar-rands
  (lambda (rands env)
    (if (null? rands)
        '()
        ;; se evalúa primero la cabeza para respetar el orden izq. a der.
        (let ((primer-valor (evaluar-expresion (car rands) env)))
          (cons primer-valor
                (evaluar-rands (cdr rands) env))))))

;; evaluar-expresion : expresion x ambiente -> valor
;; Recorre el árbol de sintaxis abstracta con cases y evalúa cada
;; variante según la semántica del enunciado. El if liga el resultado de
;; la condición a test-value, lo verifica con boolean? y solo entonces
;; ramifica; el case evalúa la expresión de control una sola vez.
(define evaluar-expresion
  (lambda (exp env)
    (cases expresion exp
      ;; un número se devuelve tal cual
      (lit-exp (dato)
        dato)
      ;; se busca la variable en el ambiente
      (var-exp (id)
        (apply-env env id))
      (true-exp ()
        #t)
      (false-exp ()
        #f)
      ;; se evaluan los argumentos y se aplica la primitiva
      (prim-exp (prim rands)
        (evaluar-primitiva prim (evaluar-rands rands env)))
      ;; la condición debe ser booleana, si no se levanta error
      (if-exp (test-exp true-exp false-exp)
        (let ((test-value (evaluar-expresion test-exp env)))
          (if (boolean? test-value)
              (if test-value
                  (evaluar-expresion true-exp env)
                  (evaluar-expresion false-exp env))
              (eopl:error 'evaluar-expresion
                          "La condicion de if debe ser booleana: ~s"
                          test-value))))
      ;; los valores se evaluan en el ambiente actual y el cuerpo en el extendido
      (let-exp (ids rands body)
        (evaluar-expresion body
                           (ambiente-extendido ids
                                               (evaluar-rands rands env)
                                               env)))
      ;; el cuerpo no se evalua, solo se guarda con el ambiente actual
      (proc-exp (ids body)
        (cerradura ids body env))
      ;; el operador debe ser un procedimiento, si no se levanta error
      (app-exp (rator rands)
        (let ((proc (evaluar-expresion rator env)))
          (if (procval? proc)
              (apply-procedure proc (evaluar-rands rands env))
              (eopl:error 'evaluar-expresion
                          "El operador de apply no es un procedimiento: ~s"
                          proc))))
      ;; el cuerpo se evalua en un ambiente-recursivo con los procedimientos
      (letrec-exp (proc-names idss bodies body)
        (let ((env-recursivo
               (ambiente-recursivo proc-names idss bodies env)))
          (evaluar-expresion body env-recursivo)))
      ;; la expresion de control se evalua una sola vez y debe ser numero
      (case-exp (control valores acciones default)
        (let ((valor-control (evaluar-expresion control env)))
          (if (number? valor-control)
              ;; evaluar-rama : lista de numeros x lista de expresiones -> valor
              ;; Recorre las ramas en orden y evalúa la acción de la primera
              ;; que coincida; si no hay ninguna, evalúa la rama otherwise.
              (letrec ((evaluar-rama
                        (lambda (resto-valores resto-acciones)
                          (if (null? resto-valores)
                              (evaluar-expresion default env)
                              (if (= valor-control (car resto-valores))
                                  (evaluar-expresion (car resto-acciones) env)
                                  (evaluar-rama (cdr resto-valores)
                                                 (cdr resto-acciones)))))))
                (evaluar-rama valores acciones))
              (eopl:error 'evaluar-expresion
                          "La expresion de control de case debe ser numerica: ~s"
                          valor-control)))))))

(provide (all-defined-out))