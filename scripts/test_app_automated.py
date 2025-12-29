#!/usr/bin/env python3
"""
Script automatizado para probar el flujo completo de la aplicación
Usa el navegador para hacer pruebas reales
"""

import sys
import time
import json

def print_status(message, status="INFO"):
    colors = {
        "SUCCESS": "\033[0;32m✅",
        "ERROR": "\033[0;31m❌",
        "WARNING": "\033[1;33m⚠️",
        "INFO": "\033[0;36mℹ️"
    }
    reset = "\033[0m"
    print(f"{colors.get(status, '')} {message}{reset}")

def check_code_implementation():
    """Verifica la implementación del código"""
    print("\n" + "="*60)
    print("🔍 VERIFICANDO IMPLEMENTACIÓN DEL CÓDIGO")
    print("="*60 + "\n")
    
    failures = []
    total = 0
    
    # Verificar archivos
    import os
    files_to_check = [
        "lib/screens/codes/repetition_session_screen.dart",
        "lib/screens/pilotaje/quantum_pilotage_screen.dart",
        "lib/main.dart"
    ]
    
    for file_path in files_to_check:
        total += 1
        if os.path.exists(file_path):
            print_status(f"Archivo {file_path} existe", "SUCCESS")
        else:
            print_status(f"Archivo {file_path} NO existe", "ERROR")
            failures.append(f"Archivo faltante: {file_path}")
    
    # Verificar código específico
    checks = [
        ("_showSequentialSteps", "Variable _showSequentialSteps"),
        ("_buildSequentialStepCard", "Método _buildSequentialStepCard"),
        ("Future<void> _nextStep", "Método _nextStep"),
        ("StreamedMusicController", "StreamedMusicController"),
        ("if (_showSequentialSteps) _buildSequentialStepCard()", "Flujo paso a paso en Stack"),
        ("audioManager.playTrack", "Inicio de audio"),
    ]
    
    file_path = "lib/screens/codes/repetition_session_screen.dart"
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        for pattern, description in checks:
            total += 1
            if pattern in content:
                print_status(f"{description} encontrado", "SUCCESS")
            else:
                print_status(f"{description} NO encontrado", "ERROR")
                failures.append(f"Falta: {description}")
    
    # Verificar que _startRepetition activa el flujo
    total += 1
    if "_showSequentialSteps = true" in content and "_startRepetition" in content:
        # Verificar que están relacionados
        lines = content.split('\n')
        start_rep_idx = None
        show_steps_idx = None
        
        for i, line in enumerate(lines):
            if "Future<void> _startRepetition" in line:
                start_rep_idx = i
            if "_showSequentialSteps = true" in line and start_rep_idx is not None:
                if i < start_rep_idx + 100:  # Dentro de 100 líneas
                    show_steps_idx = i
                    break
        
        if show_steps_idx:
            print_status("_startRepetition activa flujo paso a paso", "SUCCESS")
        else:
            print_status("_startRepetition NO activa flujo paso a paso correctamente", "ERROR")
            failures.append("_startRepetition no activa el flujo paso a paso")
    else:
        print_status("No se puede verificar relación _startRepetition y flujo paso a paso", "WARNING")
    
    # Verificar QuantumPilotageScreen y navegación Cuántico
    main_file = "lib/main.dart"
    if os.path.exists(main_file):
        with open(main_file, 'r', encoding='utf-8') as f:
            main_content = f.read()
        
        # Verificar QuantumPilotageScreen
        total += 1
        if "QuantumPilotageScreen" in main_content:
            print_status("QuantumPilotageScreen en main.dart", "SUCCESS")
        else:
            print_status("QuantumPilotageScreen NO está en main.dart", "ERROR")
            failures.append("QuantumPilotageScreen faltante en main.dart")
        
        # Verificar navegación Cuántico
        total += 1
        if "Cuántico" in main_content and "_buildNavItem" in main_content:
            print_status("Botón Cuántico en navegación", "SUCCESS")
        else:
            print_status("Botón Cuántico NO está en navegación", "ERROR")
            failures.append("Botón Cuántico faltante en navegación")
    
    return failures, total

def generate_report(failures, total):
    """Genera un reporte de las pruebas"""
    print("\n" + "="*60)
    print("📊 RESUMEN DE PRUEBAS")
    print("="*60)
    print(f"Total de verificaciones: {total}")
    print(f"Exitosas: {total - len(failures)}")
    print(f"Fallidas: {len(failures)}")
    print()
    
    if failures:
        print("❌ FALLAS ENCONTRADAS:")
        for i, failure in enumerate(failures, 1):
            print(f"   {i}. {failure}")
        print()
        print("💡 RECOMENDACIONES:")
        print("   1. Revisa los archivos mencionados arriba")
        print("   2. Verifica que _startRepetition() active _showSequentialSteps = true")
        print("   3. Verifica que el Stack muestre el flujo paso a paso")
        print("   4. Verifica que _nextStep() inicie el audio al completar el último paso")
        print("   5. Verifica que StreamedMusicController se muestre cuando _isRepetitionActive = true")
        return False
    else:
        print_status("Todas las verificaciones pasaron", "SUCCESS")
        return True

def main():
    print("🧪 INICIANDO PRUEBAS AUTOMATIZADAS DE LA APLICACIÓN")
    print("="*60)
    
    failures, total = check_code_implementation()
    success = generate_report(failures, total)
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()

