#!/bin/bash

# 🔧 Script de Debug de la Aplicación Grabovoi
# Este script ejecuta todas las herramientas de debug disponibles

echo "🚀 INICIANDO DEBUG COMPLETO DE LA APLICACIÓN"
echo "============================================="
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: No se encontró pubspec.yaml. Ejecuta este script desde la raíz del proyecto Flutter."
    exit 1
fi

# Verificar que Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter no está instalado o no está en el PATH."
    exit 1
fi

# Verificar que Dart está instalado
if ! command -v dart &> /dev/null; then
    echo "❌ Error: Dart no está instalado o no está en el PATH."
    exit 1
fi

echo "✅ Flutter y Dart están disponibles"
echo ""

# Crear directorio de resultados si no existe
mkdir -p debug_results

# Función para ejecutar debug y capturar resultados
run_debug() {
    local debug_type=$1
    local description=$2
    
    echo "🔍 Ejecutando: $description"
    echo "----------------------------------------"
    
    # Ejecutar el debug específico
    case $debug_type in
        "complete")
            dart run lib/scripts/run_debug.dart --complete --export
            ;;
        "specific")
            dart run lib/scripts/run_debug.dart --specific --export
            ;;
        "screens")
            dart run lib/scripts/run_debug.dart --screens --export
            ;;
        "models-ai")
            dart run lib/scripts/run_debug.dart --models-ai --export
            ;;
        "all")
            dart run lib/scripts/run_debug.dart --all --export
            ;;
    esac
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ $description completado exitosamente"
    else
        echo "❌ $description falló con código de salida $exit_code"
    fi
    
    echo ""
    return $exit_code
}

# Mostrar menú de opciones
show_menu() {
    echo "Selecciona el tipo de debug a ejecutar:"
    echo ""
    echo "1) Debug Completo (recomendado)"
    echo "2) Diagnóstico Específico"
    echo "3) Pruebas de Pantallas"
    echo "4) Pruebas de Modelos e IA"
    echo "5) Ejecutar Todo"
    echo "6) Ver resultados anteriores"
    echo "7) Salir"
    echo ""
    echo -n "Ingresa tu opción (1-7): "
}

# Ver resultados anteriores
show_previous_results() {
    echo "📁 Resultados anteriores disponibles:"
    echo "====================================="
    
    if [ -d "debug_results" ] && [ "$(ls -A debug_results)" ]; then
        ls -la debug_results/*.json 2>/dev/null | while read line; do
            echo "📄 $line"
        done
    else
        echo "No hay resultados anteriores disponibles."
    fi
    
    echo ""
    echo "Para ver el contenido de un archivo, usa:"
    echo "cat debug_results/nombre_del_archivo.json"
    echo ""
}

# Procesar opción del menú
process_option() {
    local option=$1
    
    case $option in
        1)
            run_debug "complete" "Debug Completo"
            ;;
        2)
            run_debug "specific" "Diagnóstico Específico"
            ;;
        3)
            run_debug "screens" "Pruebas de Pantallas"
            ;;
        4)
            run_debug "models-ai" "Pruebas de Modelos e IA"
            ;;
        5)
            run_debug "all" "Ejecutar Todo"
            ;;
        6)
            show_previous_results
            ;;
        7)
            echo "👋 ¡Hasta luego!"
            exit 0
            ;;
        *)
            echo "❌ Opción inválida. Por favor selecciona 1-7."
            ;;
    esac
}

# Verificar argumentos de línea de comandos
if [ $# -eq 0 ]; then
    # Modo interactivo
    while true; do
        show_menu
        read option
        process_option $option
        echo ""
        echo "Presiona Enter para continuar..."
        read
        clear
    done
else
    # Modo de línea de comandos
    case $1 in
        "complete")
            run_debug "complete" "Debug Completo"
            ;;
        "specific")
            run_debug "specific" "Diagnóstico Específico"
            ;;
        "screens")
            run_debug "screens" "Pruebas de Pantallas"
            ;;
        "models-ai")
            run_debug "models-ai" "Pruebas de Modelos e IA"
            ;;
        "all")
            run_debug "all" "Ejecutar Todo"
            ;;
        "results")
            show_previous_results
            ;;
        "help"|"-h"|"--help")
            echo "🔧 Script de Debug de la Aplicación Grabovoi"
            echo "============================================="
            echo ""
            echo "Uso:"
            echo "  ./debug_app.sh                    # Modo interactivo"
            echo "  ./debug_app.sh [opción]           # Modo de línea de comandos"
            echo ""
            echo "Opciones:"
            echo "  complete     Ejecutar debug completo"
            echo "  specific     Ejecutar diagnóstico específico"
            echo "  screens      Ejecutar pruebas de pantallas"
            echo "  models-ai    Ejecutar pruebas de modelos e IA"
            echo "  all          Ejecutar todas las pruebas"
            echo "  results      Mostrar resultados anteriores"
            echo "  help         Mostrar esta ayuda"
            echo ""
            echo "Ejemplos:"
            echo "  ./debug_app.sh complete"
            echo "  ./debug_app.sh all"
            echo "  ./debug_app.sh results"
            ;;
        *)
            echo "❌ Opción desconocida: $1"
            echo "Usa './debug_app.sh help' para ver las opciones disponibles."
            exit 1
            ;;
    esac
fi

echo "🏁 Script de debug terminado"
echo "============================"

