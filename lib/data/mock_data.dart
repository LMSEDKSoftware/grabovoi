import '../models/grabovoi_code.dart';
import '../models/meditation.dart';

class MockData {
  static List<GrabovoiCode> getCodes() {
    return [
      // Salud
      GrabovoiCode(
        id: '1',
        code: '1814321',
        title: 'Salud general',
        description: 'Código para la armonización del estado general de salud y bienestar físico',
        category: 'salud',
        tags: ['general', 'bienestar', 'salud'],
        popularityScore: 150,
      ),
      GrabovoiCode(
        id: '2',
        code: '8142543',
        title: 'Sistema inmunológico',
        description: 'Fortalecimiento del sistema inmune y las defensas naturales del cuerpo',
        category: 'salud',
        tags: ['inmunidad', 'defensas', 'salud'],
        popularityScore: 120,
      ),
      GrabovoiCode(
        id: '3',
        code: '1489999',
        title: 'Regeneración celular',
        description: 'Código para la renovación y regeneración de células del organismo',
        category: 'salud',
        tags: ['regeneracion', 'celulas', 'renovacion'],
        popularityScore: 100,
      ),
      GrabovoiCode(
        id: '4',
        code: '5421427',
        title: 'Vitalidad y energía',
        description: 'Incremento de energía vital y fuerza interior',
        category: 'salud',
        tags: ['energia', 'vitalidad', 'fuerza'],
        popularityScore: 95,
      ),
      
      // Abundancia
      GrabovoiCode(
        id: '5',
        code: '318798',
        title: 'Abundancia financiera',
        description: 'Atracción de prosperidad económica y flujo de dinero',
        category: 'abundancia',
        tags: ['dinero', 'prosperidad', 'finanzas'],
        popularityScore: 180,
      ),
      GrabovoiCode(
        id: '6',
        code: '520741 8',
        title: 'Éxito en negocios',
        description: 'Logro y éxito en emprendimientos y proyectos comerciales',
        category: 'abundancia',
        tags: ['negocios', 'exito', 'emprendimiento'],
        popularityScore: 130,
      ),
      GrabovoiCode(
        id: '7',
        code: '71427321893',
        title: 'Dinero inesperado',
        description: 'Llegada de recursos financieros inesperados y oportunidades',
        category: 'abundancia',
        tags: ['dinero', 'sorpresa', 'fortuna'],
        popularityScore: 145,
      ),
      GrabovoiCode(
        id: '8',
        code: '4277481',
        title: 'Oportunidades laborales',
        description: 'Atracción de nuevas oportunidades de trabajo y crecimiento profesional',
        category: 'abundancia',
        tags: ['trabajo', 'oportunidades', 'empleo'],
        popularityScore: 110,
      ),
      
      // Relaciones
      GrabovoiCode(
        id: '9',
        code: '888 412 1289018',
        title: 'Amor y pareja',
        description: 'Armonía en relaciones románticas y atracción del amor verdadero',
        category: 'relaciones',
        tags: ['amor', 'pareja', 'romance'],
        popularityScore: 160,
      ),
      GrabovoiCode(
        id: '10',
        code: '5148241',
        title: 'Relaciones familiares',
        description: 'Paz y armonía en el núcleo familiar',
        category: 'relaciones',
        tags: ['familia', 'paz', 'armonia'],
        popularityScore: 105,
      ),
      GrabovoiCode(
        id: '11',
        code: '419 488 71',
        title: 'Amistad verdadera',
        description: 'Atracción de amistades genuinas y duraderas',
        category: 'relaciones',
        tags: ['amistad', 'conexion', 'compania'],
        popularityScore: 90,
      ),
      
      // Crecimiento Personal
      GrabovoiCode(
        id: '12',
        code: '818 818 198717',
        title: 'Desarrollo espiritual',
        description: 'Crecimiento y evolución espiritual, expansión de conciencia',
        category: 'crecimiento_personal',
        tags: ['espiritual', 'evolucion', 'conciencia'],
        popularityScore: 140,
      ),
      GrabovoiCode(
        id: '13',
        code: '5391428',
        title: 'Confianza y autoestima',
        description: 'Fortalecimiento de la confianza personal y amor propio',
        category: 'crecimiento_personal',
        tags: ['confianza', 'autoestima', 'seguridad'],
        popularityScore: 125,
      ),
      GrabovoiCode(
        id: '14',
        code: '4812412',
        title: 'Creatividad',
        description: 'Expansión de la capacidad creativa e inspiración artística',
        category: 'crecimiento_personal',
        tags: ['creatividad', 'inspiracion', 'arte'],
        popularityScore: 115,
      ),
      
      // Protección
      GrabovoiCode(
        id: '15',
        code: '9187756981818',
        title: 'Protección general',
        description: 'Escudo protector energético contra influencias negativas',
        category: 'proteccion',
        tags: ['proteccion', 'escudo', 'seguridad'],
        popularityScore: 135,
      ),
      GrabovoiCode(
        id: '16',
        code: '71427321893',
        title: 'Protección del hogar',
        description: 'Armonía y protección en el hogar y espacio personal',
        category: 'proteccion',
        tags: ['hogar', 'casa', 'espacio'],
        popularityScore: 108,
      ),
      
      // Armonía
      GrabovoiCode(
        id: '17',
        code: '14854232190',
        title: 'Paz interior',
        description: 'Calma y tranquilidad del ser, equilibrio emocional',
        category: 'armonia',
        tags: ['paz', 'calma', 'tranquilidad'],
        popularityScore: 155,
      ),
      GrabovoiCode(
        id: '18',
        code: '5214588',
        title: 'Balance emocional',
        description: 'Equilibrio de las emociones y estabilidad mental',
        category: 'armonia',
        tags: ['emociones', 'balance', 'equilibrio'],
        popularityScore: 118,
      ),
      GrabovoiCode(
        id: '19',
        code: '741 741 741',
        title: 'Sanación holística',
        description: 'Sanación integral del ser en todos los niveles',
        category: 'armonia',
        tags: ['sanacion', 'holistico', 'integral'],
        popularityScore: 142,
      ),
      GrabovoiCode(
        id: '20',
        code: '1888948',
        title: 'Armonía universal',
        description: 'Conexión con la armonía del universo y sincronicidad',
        category: 'armonia',
        tags: ['universo', 'conexion', 'armonia'],
        popularityScore: 128,
      ),
    ];
  }

  static List<Meditation> getMeditations() {
    return [
      Meditation(
        id: '1',
        title: 'Respiración 4-7-8',
        description: 'Técnica de respiración relajante para calmar el sistema nervioso',
        durationMinutes: 5,
        type: 'respiracion',
        difficulty: 'principiante',
        benefits: ['Reduce ansiedad', 'Mejora el sueño', 'Calma la mente'],
        scriptText: 'Siéntate cómodamente con la espalda recta.\n\n'
            'Inhala profundamente por la nariz contando hasta 4.\n'
            'Sostén la respiración contando hasta 7.\n'
            'Exhala completamente por la boca contando hasta 8.\n\n'
            'Repite este ciclo 4 veces.',
      ),
      Meditation(
        id: '2',
        title: 'Meditación guiada de manifestación',
        description: 'Visualización para manifestar tus intenciones con códigos Grabovoi',
        durationMinutes: 15,
        type: 'guiada',
        difficulty: 'intermedio',
        benefits: ['Clarifica intenciones', 'Fortalece visualización', 'Conecta con objetivos'],
        scriptText: 'Siéntate cómodamente y cierra los ojos.\n\n'
            'Respira profundamente tres veces.\n\n'
            'Visualiza tu intención como si ya fuera realidad.\n'
            'Siente las emociones de haberlo logrado.\n\n'
            'Mientras respiras, repite mentalmente el código Grabovoi que elegiste.\n'
            'Permite que los números fluyan con tu respiración.',
      ),
      Meditation(
        id: '3',
        title: 'Pilotaje de realidad',
        description: 'Ejercicio de pilotaje para dirigir eventos futuros',
        durationMinutes: 20,
        type: 'pilotaje',
        difficulty: 'avanzado',
        benefits: ['Dirige tu realidad', 'Crea tu futuro', 'Poder de intención'],
        scriptText: 'Cierra los ojos y respira profundamente.\n\n'
            'Imagina una esfera de luz dorada frente a ti.\n'
            'En ella, proyecta la situación que deseas crear.\n'
            'Observa los detalles con claridad: colores, sonidos, sensaciones.\n\n'
            'Pronuncia el código correspondiente tres veces con intención.\n'
            'Siente cómo la esfera se integra en tu realidad.',
      ),
      Meditation(
        id: '4',
        title: 'Micro-meditación del momento presente',
        description: 'Conexión rápida con el aquí y ahora',
        durationMinutes: 5,
        type: 'guiada',
        difficulty: 'principiante',
        benefits: ['Reduce estrés', 'Aumenta presencia', 'Calma rápida'],
        scriptText: 'Toma tres respiraciones profundas.\n\n'
            'Nota cinco cosas que puedes ver.\n'
            'Cuatro que puedes tocar.\n'
            'Tres que puedes escuchar.\n'
            'Dos que puedes oler.\n'
            'Una que puedes saborear.\n\n'
            'Regresa a tu respiración.',
      ),
      Meditation(
        id: '5',
        title: 'Visualización de abundancia',
        description: 'Ejercicio de visualización para atraer prosperidad',
        durationMinutes: 10,
        type: 'visualizacion',
        difficulty: 'principiante',
        benefits: ['Atrae prosperidad', 'Cambia mentalidad', 'Genera gratitud'],
        scriptText: 'Siéntate cómodamente y cierra los ojos.\n\n'
            'Imagina una lluvia dorada de abundancia cayendo sobre ti.\n'
            'Siente la prosperidad en cada célula de tu cuerpo.\n\n'
            'Repite: "Soy un imán de abundancia y prosperidad".\n'
            'Visualiza tu vida llena de abundancia en todas sus formas.',
      ),
      Meditation(
        id: '6',
        title: 'Conexión con el corazón',
        description: 'Meditación para conectar con tu sabiduría interior',
        durationMinutes: 12,
        type: 'guiada',
        difficulty: 'intermedio',
        benefits: ['Claridad interior', 'Paz emocional', 'Intuición'],
        scriptText: 'Coloca tu mano sobre tu corazón.\n\n'
            'Respira hacia tu corazón, sintiendo su latido.\n'
            'Con cada inhalación, llena tu corazón de luz.\n'
            'Con cada exhalación, expande esa luz a todo tu ser.\n\n'
            'Escucha lo que tu corazón tiene que decirte.',
      ),
    ];
  }
}

