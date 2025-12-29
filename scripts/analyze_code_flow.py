#!/usr/bin/env python3
"""
Análisis detallado del flujo del código para detectar problemas lógicos
"""

import re
import os

def print_status(message, status="INFO"):
    colors = {
        "SUCCESS": "\033[0;32m✅",
        "ERROR": "\033[0;31m❌",
        "WARNING": "\033[1;33m⚠️",
        "INFO": "\033[0;36mℹ️"
    }
    reset = "\033[0m"
    print(f"{colors.get(status, '')} {message}{reset}")

def analyze_repetition_session():
    """Analiza el flujo completo de repetition_session_screen.dart"""
    print("\n" + "="*60)
    print("🔍 ANÁLISIS DETALLADO DEL FLUJO DE REPETICIÓN")
    print("="*60 + "\n")
    
    file_path = "lib/screens/codes/repetition_session_screen.dart"
    if not os.path.exists(file_path):
        print_status("Archivo no encontrado", "ERROR")
        return
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    issues = []
    
    # 1. Verificar que _startRepetition activa _showSequentialSteps
    print("1. Verificando _startRepetition()...")
    start_rep_match = re.search(r'Future<void> _startRepetition\(\)[^{]*\{([^}]*\{[^}]*\}[^}]*)*', content, re.DOTALL)
    if start_rep_match:
        start_rep_content = start_rep_match.group(0)
        if "_showSequentialSteps = true" in start_rep_content:
            print_status("   _startRepetition activa _showSequentialSteps", "SUCCESS")
        else:
            print_status("   _startRepetition NO activa _showSequentialSteps", "ERROR")
            issues.append("_startRepetition no activa el flujo paso a paso")
    else:
        print_status("   No se pudo encontrar _startRepetition", "WARNING")
    
    # 2. Verificar que _nextStep inicia el audio
    print("\n2. Verificando _nextStep()...")
    next_step_match = re.search(r'Future<void> _nextStep\(\)[^{]*\{([^}]*\{[^}]*\}[^}]*)*', content, re.DOTALL)
    if next_step_match:
        next_step_content = next_step_match.group(0)
        if "audioManager.playTrack" in next_step_content:
            print_status("   _nextStep inicia el audio", "SUCCESS")
            # Verificar que está en el else (último paso)
            if "} else {" in next_step_content or "_currentStepIndex < 5" in next_step_content:
                print_status("   Audio se inicia en el último paso", "SUCCESS")
            else:
                print_status("   Verificar que audio se inicia solo en último paso", "WARNING")
        else:
            print_status("   _nextStep NO inicia el audio", "ERROR")
            issues.append("_nextStep no inicia el audio")
    else:
        print_status("   No se pudo encontrar _nextStep", "WARNING")
    
    # 3. Verificar que el Stack muestra el flujo paso a paso
    print("\n3. Verificando Stack y visualización...")
    stack_match = re.search(r'Stack\s*\([^)]*children:\s*\[([^\]]*)\]', content, re.DOTALL)
    if stack_match:
        stack_children = stack_match.group(1)
        if "if (_showSequentialSteps) _buildSequentialStepCard()" in stack_children:
            print_status("   Stack muestra flujo paso a paso condicionalmente", "SUCCESS")
        else:
            print_status("   Stack NO muestra flujo paso a paso", "ERROR")
            issues.append("Stack no muestra el flujo paso a paso")
    else:
        print_status("   No se pudo encontrar Stack", "WARNING")
    
    # 4. Verificar que StreamedMusicController se muestra
    print("\n4. Verificando StreamedMusicController...")
    if "StreamedMusicController" in content:
        # Buscar cómo se muestra
        smc_pattern = r'StreamedMusicController\s*\([^)]*\)'
        smc_matches = re.findall(smc_pattern, content)
        if smc_matches:
            for match in smc_matches:
                if "autoPlay: _isRepetitionActive" in match or "autoPlay: true" in match:
                    print_status("   StreamedMusicController configurado correctamente", "SUCCESS")
                    break
            else:
                print_status("   Verificar configuración de StreamedMusicController", "WARNING")
        else:
            print_status("   StreamedMusicController no encontrado en uso", "ERROR")
            issues.append("StreamedMusicController no está siendo usado")
    else:
        print_status("   StreamedMusicController no importado/encontrado", "ERROR")
        issues.append("StreamedMusicController no encontrado")
    
    # 5. Verificar orden de elementos en Stack
    print("\n5. Verificando orden de elementos en Stack...")
    # El flujo paso a paso debe estar ANTES del GlowBackground para que se muestre encima
    stack_section = content[content.find("body: Stack"):content.find("body: Stack") + 500]
    if "_buildSequentialStepCard()" in stack_section:
        # Buscar posición relativa
        sequential_pos = stack_section.find("_buildSequentialStepCard()")
        glow_pos = stack_section.find("GlowBackground")
        if sequential_pos < glow_pos:
            print_status("   Flujo paso a paso está antes de GlowBackground (correcto)", "SUCCESS")
        else:
            print_status("   Flujo paso a paso está después de GlowBackground (puede estar oculto)", "WARNING")
            issues.append("Orden incorrecto en Stack: flujo paso a paso puede estar oculto")
    
    # 6. Verificar que _buildSequentialStepCard retorna Positioned.fill
    print("\n6. Verificando _buildSequentialStepCard()...")
    if "Widget _buildSequentialStepCard()" in content:
        build_card_match = re.search(r'Widget _buildSequentialStepCard\(\)[^{]*\{([^}]*\{[^}]*\}[^}]*)*return\s+([^;]+);', content, re.DOTALL)
        if build_card_match:
            return_statement = build_card_match.group(2)
            if "Positioned.fill" in return_statement:
                print_status("   _buildSequentialStepCard retorna Positioned.fill (correcto)", "SUCCESS")
            else:
                print_status("   _buildSequentialStepCard NO retorna Positioned.fill", "ERROR")
                issues.append("_buildSequentialStepCard no retorna Positioned.fill")
        else:
            print_status("   No se pudo analizar el return de _buildSequentialStepCard", "WARNING")
    
    return issues

def main():
    print("🧪 ANÁLISIS DETALLADO DEL FLUJO DE CÓDIGO")
    print("="*60)
    
    issues = analyze_repetition_session()
    
    print("\n" + "="*60)
    print("📊 RESUMEN DE ANÁLISIS")
    print("="*60)
    
    if issues:
        print(f"\n❌ Se encontraron {len(issues)} problemas:")
        for i, issue in enumerate(issues, 1):
            print(f"   {i}. {issue}")
        print("\n💡 Estos problemas pueden impedir que el flujo paso a paso se muestre correctamente.")
        return False
    else:
        print_status("\n✅ No se encontraron problemas en el análisis", "SUCCESS")
        print("\n💡 Si el flujo paso a paso aún no se muestra, puede ser un problema de:")
        print("   - Timing: el setState puede no estar actualizando la UI")
        print("   - Context: el widget puede no estar montado")
        print("   - Renderizado: puede haber un problema de z-index o overlay")
        return True

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)

