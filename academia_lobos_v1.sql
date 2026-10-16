-- ============================================================
-- ACADEMIA LOBOS - BASE DE DATOS INICIAL FUNCIONAL
-- Motor: MySQL 8.0.16+ (CHECK constraints aplicados)
-- Charset: utf8mb4
-- Nota: ejecutar en una base NUEVA. El script elimina la BD previa
-- con el mismo nombre para permitir instalaciones limpias.
-- ============================================================

DROP DATABASE IF EXISTS academia_lobos;
CREATE DATABASE academia_lobos CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE academia_lobos;

-- -------------------------- PERSONAS Y ACCESO -----------------
CREATE TABLE persona (
  id_persona BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  apellido_paterno VARCHAR(100) NOT NULL,
  apellido_materno VARCHAR(100) NULL,
  fecha_nacimiento DATE NULL,
  telefono VARCHAR(25) NULL,
  correo VARCHAR(150) NULL,
  domicilio VARCHAR(255) NULL,
  curp CHAR(18) NULL UNIQUE,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE usuario (
  id_usuario BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_persona BIGINT UNSIGNED NOT NULL UNIQUE,
  nombre_usuario VARCHAR(80) NOT NULL UNIQUE,
  contrasena_hash VARCHAR(255) NOT NULL COMMENT 'Guardar hash seguro, nunca contraseña en texto plano',
  rol ENUM('ADMINISTRADOR','PROFESOR','RESPONSABLE','ALUMNO') NOT NULL,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  ultimo_acceso DATETIME NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_usuario_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE alumno (
  id_alumno BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_persona BIGINT UNSIGNED NOT NULL UNIQUE,
  fecha_ingreso DATE NOT NULL,
  escuela VARCHAR(150) NULL,
  numero_playera SMALLINT UNSIGNED NOT NULL UNIQUE,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_alumno_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE responsable (
  id_responsable BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_persona BIGINT UNSIGNED NOT NULL UNIQUE,
  parentesco_principal VARCHAR(40) NULL,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  CONSTRAINT fk_responsable_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE alumno_responsable (
  id_alumno_responsable BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  id_responsable BIGINT UNSIGNED NOT NULL,
  parentesco ENUM('PADRE','MADRE','TUTOR','OTRO') NOT NULL,
  es_tutor BOOLEAN NOT NULL DEFAULT FALSE,
  es_contacto_principal BOOLEAN NOT NULL DEFAULT FALSE,
  fecha_asignacion DATE NOT NULL DEFAULT (CURRENT_DATE),
  CONSTRAINT uq_alumno_responsable UNIQUE (id_alumno,id_responsable),
  CONSTRAINT fk_ar_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON DELETE RESTRICT,
  CONSTRAINT fk_ar_responsable FOREIGN KEY (id_responsable) REFERENCES responsable(id_responsable) ON DELETE RESTRICT,
  INDEX idx_ar_responsable (id_responsable)
) ENGINE=InnoDB;

CREATE TABLE personal (
  id_personal BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_persona BIGINT UNSIGNED NOT NULL UNIQUE,
  puesto VARCHAR(100) NOT NULL,
  fecha_ingreso DATE NULL,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  CONSTRAINT fk_personal_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE profesor (
  id_profesor BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_personal BIGINT UNSIGNED NOT NULL UNIQUE,
  especialidad VARCHAR(150) NULL,
  CONSTRAINT fk_profesor_personal FOREIGN KEY (id_personal) REFERENCES personal(id_personal) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE informacion_medica (
  id_medica BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL UNIQUE,
  tipo_sangre VARCHAR(5) NULL,
  alergias TEXT NULL,
  seguro_medico VARCHAR(150) NULL,
  observaciones_medicas TEXT NULL,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_medica_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------ DOCUMENTOS -------------------
CREATE TABLE tipo_documento (
  id_tipo_documento BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion VARCHAR(255) NULL,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB;

CREATE TABLE documento (
  id_documento BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  id_tipo_documento BIGINT UNSIGNED NOT NULL,
  id_usuario_carga BIGINT UNSIGNED NOT NULL,
  nombre_archivo VARCHAR(255) NOT NULL,
  ruta_archivo VARCHAR(700) NOT NULL,
  fecha_carga DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado ENUM('ACTIVO','ELIMINADO') NOT NULL DEFAULT 'ACTIVO',
  version_de BIGINT UNSIGNED NULL,
  CONSTRAINT fk_documento_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON DELETE RESTRICT,
  CONSTRAINT fk_documento_tipo FOREIGN KEY (id_tipo_documento) REFERENCES tipo_documento(id_tipo_documento) ON DELETE RESTRICT,
  CONSTRAINT fk_documento_usuario FOREIGN KEY (id_usuario_carga) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
  CONSTRAINT fk_documento_version FOREIGN KEY (version_de) REFERENCES documento(id_documento) ON DELETE SET NULL,
  INDEX idx_documento_alumno_estado (id_alumno,estado),
  INDEX idx_documento_tipo_alumno (id_tipo_documento,id_alumno)
) ENGINE=InnoDB;

-- ------------------------------ EQUIPOS ----------------------
CREATE TABLE equipo (
  id_equipo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  rango_anios VARCHAR(20) NOT NULL UNIQUE,
  anio_inicio SMALLINT UNSIGNED NULL,
  anio_fin SMALLINT UNSIGNED NULL,
  descripcion VARCHAR(255) NULL,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  CONSTRAINT chk_equipo_anios CHECK (anio_inicio IS NULL OR anio_fin IS NULL OR anio_fin >= anio_inicio)
) ENGINE=InnoDB;

CREATE TABLE profesor_equipo (
  id_profesor_equipo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_profesor BIGINT UNSIGNED NOT NULL,
  id_equipo BIGINT UNSIGNED NOT NULL,
  tipo_participacion ENUM('PRINCIPAL','AUXILIAR') NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NULL,
  CONSTRAINT fk_pe_profesor FOREIGN KEY (id_profesor) REFERENCES profesor(id_profesor) ON DELETE RESTRICT,
  CONSTRAINT fk_pe_equipo FOREIGN KEY (id_equipo) REFERENCES equipo(id_equipo) ON DELETE RESTRICT,
  CONSTRAINT chk_pe_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
  INDEX idx_pe_equipo_activo (id_equipo,fecha_fin,tipo_participacion),
  INDEX idx_pe_profesor (id_profesor,fecha_fin)
) ENGINE=InnoDB;

CREATE TABLE alumno_equipo (
  id_alumno_equipo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  id_equipo BIGINT UNSIGNED NOT NULL,
  tipo_participacion ENUM('PRINCIPAL','REFUERZO') NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NULL,
  CONSTRAINT fk_ae_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON DELETE RESTRICT,
  CONSTRAINT fk_ae_equipo FOREIGN KEY (id_equipo) REFERENCES equipo(id_equipo) ON DELETE RESTRICT,
  CONSTRAINT chk_ae_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
  INDEX idx_ae_alumno_vigencia (id_alumno,fecha_inicio,fecha_fin),
  INDEX idx_ae_equipo_vigencia (id_equipo,fecha_inicio,fecha_fin)
) ENGINE=InnoDB;

-- --------------------------- ENTRENAMIENTOS ------------------
CREATE TABLE entrenamiento (
  id_entrenamiento BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_equipo BIGINT UNSIGNED NOT NULL,
  fecha DATE NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fin TIME NULL,
  tipo_recurrencia ENUM('UNICO','SEMANAL') NOT NULL DEFAULT 'UNICO',
  observaciones TEXT NULL,
  estado ENUM('PROGRAMADO','REALIZADO','CANCELADO') NOT NULL DEFAULT 'PROGRAMADO',
  creado_por BIGINT UNSIGNED NOT NULL,
  CONSTRAINT fk_entrenamiento_equipo FOREIGN KEY (id_equipo) REFERENCES equipo(id_equipo) ON DELETE RESTRICT,
  CONSTRAINT fk_entrenamiento_usuario FOREIGN KEY (creado_por) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
  CONSTRAINT chk_entrenamiento_horas CHECK (hora_fin IS NULL OR hora_fin > hora_inicio),
  INDEX idx_entrenamiento_equipo_fecha (id_equipo,fecha)
) ENGINE=InnoDB;

CREATE TABLE ejercicio (
  id_ejercicio BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT NULL,
  objetivo TEXT NULL,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  creado_por BIGINT UNSIGNED NULL,
  CONSTRAINT fk_ejercicio_usuario FOREIGN KEY (creado_por) REFERENCES usuario(id_usuario) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE planeacion (
  id_planeacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_entrenamiento BIGINT UNSIGNED NULL UNIQUE,
  nombre_plantilla VARCHAR(150) NULL,
  objetivo TEXT NULL,
  observaciones TEXT NULL,
  es_plantilla BOOLEAN NOT NULL DEFAULT FALSE,
  creada_por BIGINT UNSIGNED NOT NULL,
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_planeacion_entrenamiento FOREIGN KEY (id_entrenamiento) REFERENCES entrenamiento(id_entrenamiento) ON DELETE RESTRICT,
  CONSTRAINT fk_planeacion_usuario FOREIGN KEY (creada_por) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
  CONSTRAINT chk_planeacion_tipo CHECK (
    (es_plantilla = TRUE AND id_entrenamiento IS NULL AND nombre_plantilla IS NOT NULL) OR
    (es_plantilla = FALSE AND id_entrenamiento IS NOT NULL)
  )
) ENGINE=InnoDB;

CREATE TABLE planeacion_ejercicio (
  id_planeacion_ejercicio BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_planeacion BIGINT UNSIGNED NOT NULL,
  id_ejercicio BIGINT UNSIGNED NOT NULL,
  orden SMALLINT UNSIGNED NOT NULL,
  duracion_minutos SMALLINT UNSIGNED NULL,
  observaciones TEXT NULL,
  CONSTRAINT fk_pej_planeacion FOREIGN KEY (id_planeacion) REFERENCES planeacion(id_planeacion) ON DELETE CASCADE,
  CONSTRAINT fk_pej_ejercicio FOREIGN KEY (id_ejercicio) REFERENCES ejercicio(id_ejercicio) ON DELETE RESTRICT,
  CONSTRAINT uq_planeacion_orden UNIQUE (id_planeacion,orden),
  CONSTRAINT chk_pej_orden CHECK (orden > 0)
) ENGINE=InnoDB;

CREATE TABLE asistencia (
  id_asistencia BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_entrenamiento BIGINT UNSIGNED NOT NULL,
  id_alumno BIGINT UNSIGNED NOT NULL,
  estado ENUM('PRESENTE','AUSENTE','JUSTIFICADO','RETARDO') NOT NULL,
  observaciones VARCHAR(255) NULL,
  CONSTRAINT fk_asistencia_entrenamiento FOREIGN KEY (id_entrenamiento) REFERENCES entrenamiento(id_entrenamiento) ON DELETE RESTRICT,
  CONSTRAINT fk_asistencia_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON DELETE RESTRICT,
  CONSTRAINT uq_asistencia UNIQUE (id_entrenamiento,id_alumno)
) ENGINE=InnoDB;

CREATE TABLE asistencia_profesor (
  id_asistencia_profesor BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_entrenamiento BIGINT UNSIGNED NOT NULL,
  id_profesor BIGINT UNSIGNED NOT NULL,
  asistio BOOLEAN NOT NULL,
  observaciones VARCHAR(255) NULL,
  CONSTRAINT fk_asistencia_prof_entrenamiento FOREIGN KEY (id_entrenamiento) REFERENCES entrenamiento(id_entrenamiento) ON DELETE RESTRICT,
  CONSTRAINT fk_asistencia_prof_profesor FOREIGN KEY (id_profesor) REFERENCES profesor(id_profesor) ON DELETE RESTRICT,
  CONSTRAINT uq_asistencia_profesor UNIQUE (id_entrenamiento,id_profesor)
) ENGINE=InnoDB;

-- ------------------------------- PARTIDOS --------------------
CREATE TABLE torneo (
  id_torneo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  descripcion VARCHAR(255) NULL,
  fecha_inicio DATE NULL,
  fecha_fin DATE NULL,
  estado ENUM('ACTIVO','FINALIZADO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  CONSTRAINT chk_torneo_fechas CHECK (fecha_fin IS NULL OR fecha_inicio IS NULL OR fecha_fin >= fecha_inicio)
) ENGINE=InnoDB;

CREATE TABLE tipo_partido (
  id_tipo_partido BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB;

CREATE TABLE partido (
  id_partido BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_equipo BIGINT UNSIGNED NOT NULL,
  id_torneo BIGINT UNSIGNED NULL,
  id_tipo_partido BIGINT UNSIGNED NOT NULL,
  rival VARCHAR(150) NOT NULL,
  fecha DATE NOT NULL,
  hora TIME NULL,
  local_visitante ENUM('LOCAL','VISITANTE','NEUTRAL') NOT NULL DEFAULT 'LOCAL',
  goles_favor SMALLINT UNSIGNED NULL,
  goles_contra SMALLINT UNSIGNED NULL,
  estado ENUM('PROGRAMADO','JUGADO','CANCELADO') NOT NULL DEFAULT 'PROGRAMADO',
  observaciones TEXT NULL,
  creado_por BIGINT UNSIGNED NOT NULL,
  CONSTRAINT fk_partido_equipo FOREIGN KEY (id_equipo) REFERENCES equipo(id_equipo) ON DELETE RESTRICT,
  CONSTRAINT fk_partido_torneo FOREIGN KEY (id_torneo) REFERENCES torneo(id_torneo) ON DELETE RESTRICT,
  CONSTRAINT fk_partido_tipo FOREIGN KEY (id_tipo_partido) REFERENCES tipo_partido(id_tipo_partido) ON DELETE RESTRICT,
  CONSTRAINT fk_partido_usuario FOREIGN KEY (creado_por) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
  CONSTRAINT chk_partido_marcador CHECK (
    (goles_favor IS NULL AND goles_contra IS NULL) OR
    (goles_favor IS NOT NULL AND goles_contra IS NOT NULL)
  ),
  INDEX idx_partido_equipo_fecha (id_equipo,fecha)
) ENGINE=InnoDB;

CREATE TABLE convocatoria (
  id_convocatoria BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_partido BIGINT UNSIGNED NOT NULL,
  id_alumno BIGINT UNSIGNED NOT NULL,
  convocado BOOLEAN NOT NULL DEFAULT TRUE,
  participo BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_convocatoria_partido FOREIGN KEY (id_partido) REFERENCES partido(id_partido) ON DELETE RESTRICT,
  CONSTRAINT fk_convocatoria_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON DELETE RESTRICT,
  CONSTRAINT uq_convocatoria UNIQUE (id_partido,id_alumno)
) ENGINE=InnoDB;

CREATE TABLE estadistica_partido (
  id_estadistica BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_partido BIGINT UNSIGNED NOT NULL,
  id_alumno BIGINT UNSIGNED NOT NULL,
  goles SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  asistencias SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  minutos SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  tarjetas_amarillas TINYINT UNSIGNED NOT NULL DEFAULT 0,
  tarjetas_rojas TINYINT UNSIGNED NOT NULL DEFAULT 0,
  CONSTRAINT fk_estadistica_partido FOREIGN KEY (id_partido) REFERENCES partido(id_partido) ON DELETE RESTRICT,
  CONSTRAINT fk_estadistica_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON DELETE RESTRICT,
  CONSTRAINT uq_estadistica_partido_alumno UNIQUE (id_partido,id_alumno)
) ENGINE=InnoDB;

-- ----------------------------- EVALUACIONES ------------------
CREATE TABLE tipo_evaluacion (
  id_tipo_evaluacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre ENUM('TECNICO','TACTICO','FISICO','MENTAL') NOT NULL UNIQUE,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB;

CREATE TABLE criterio_evaluacion (
  id_criterio BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_tipo_evaluacion BIGINT UNSIGNED NOT NULL,
  nombre VARCHAR(100) NOT NULL,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  CONSTRAINT fk_criterio_tipo FOREIGN KEY (id_tipo_evaluacion) REFERENCES tipo_evaluacion(id_tipo_evaluacion) ON DELETE RESTRICT,
  CONSTRAINT uq_criterio_tipo_nombre UNIQUE (id_tipo_evaluacion,nombre)
) ENGINE=InnoDB;

CREATE TABLE evaluacion (
  id_evaluacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  id_equipo BIGINT UNSIGNED NOT NULL,
  id_usuario_evaluador BIGINT UNSIGNED NOT NULL,
  fecha DATE NOT NULL DEFAULT (CURRENT_DATE),
  observaciones TEXT NULL,
  estado ENUM('BORRADOR','FINALIZADA') NOT NULL DEFAULT 'BORRADOR',
  creada_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_evaluacion_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON DELETE RESTRICT,
  CONSTRAINT fk_evaluacion_equipo FOREIGN KEY (id_equipo) REFERENCES equipo(id_equipo) ON DELETE RESTRICT,
  CONSTRAINT fk_evaluacion_usuario FOREIGN KEY (id_usuario_evaluador) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
  INDEX idx_evaluacion_alumno_fecha (id_alumno,fecha)
) ENGINE=InnoDB;

CREATE TABLE detalle_evaluacion (
  id_detalle BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_evaluacion BIGINT UNSIGNED NOT NULL,
  id_criterio BIGINT UNSIGNED NOT NULL,
  calificacion TINYINT UNSIGNED NOT NULL,
  observaciones VARCHAR(255) NULL,
  CONSTRAINT fk_detalle_evaluacion FOREIGN KEY (id_evaluacion) REFERENCES evaluacion(id_evaluacion) ON DELETE CASCADE,
  CONSTRAINT fk_detalle_criterio FOREIGN KEY (id_criterio) REFERENCES criterio_evaluacion(id_criterio) ON DELETE RESTRICT,
  CONSTRAINT uq_detalle_evaluacion_criterio UNIQUE (id_evaluacion,id_criterio),
  CONSTRAINT chk_calificacion CHECK (calificacion BETWEEN 1 AND 5)
) ENGINE=InnoDB;

-- -------------------------------- FINANZAS -------------------
CREATE TABLE concepto_pago (
  id_concepto BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion VARCHAR(255) NULL,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB;

CREATE TABLE cuota (
  id_cuota BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_concepto BIGINT UNSIGNED NOT NULL,
  monto DECIMAL(10,2) NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NULL,
  estado ENUM('ACTIVA','INACTIVA') NOT NULL DEFAULT 'ACTIVA',
  CONSTRAINT fk_cuota_concepto FOREIGN KEY (id_concepto) REFERENCES concepto_pago(id_concepto) ON DELETE RESTRICT,
  CONSTRAINT chk_cuota_monto CHECK (monto >= 0),
  CONSTRAINT chk_cuota_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
  INDEX idx_cuota_concepto_vigencia (id_concepto,fecha_inicio,fecha_fin)
) ENGINE=InnoDB;

CREATE TABLE descuento (
  id_descuento BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  tipo ENUM('PORCENTAJE','MONTO') NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  descripcion VARCHAR(255) NULL,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  CONSTRAINT chk_descuento_valor CHECK (valor >= 0 AND (tipo <> 'PORCENTAJE' OR valor <= 100))
) ENGINE=InnoDB;

CREATE TABLE alumno_descuento (
  id_alumno_descuento BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  id_descuento BIGINT UNSIGNED NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NULL,
  CONSTRAINT fk_ad_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON DELETE RESTRICT,
  CONSTRAINT fk_ad_descuento FOREIGN KEY (id_descuento) REFERENCES descuento(id_descuento) ON DELETE RESTRICT,
  CONSTRAINT chk_ad_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
  INDEX idx_ad_alumno_vigencia (id_alumno,fecha_inicio,fecha_fin)
) ENGINE=InnoDB;

CREATE TABLE cargo (
  id_cargo BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  id_cuota BIGINT UNSIGNED NOT NULL,
  periodo CHAR(7) NOT NULL COMMENT 'Formato YYYY-MM',
  fecha_generacion DATE NOT NULL DEFAULT (CURRENT_DATE),
  fecha_vencimiento DATE NULL,
  monto_original DECIMAL(10,2) NOT NULL,
  descuento_aplicado DECIMAL(10,2) NOT NULL DEFAULT 0,
  monto DECIMAL(10,2) NOT NULL,
  estado ENUM('PENDIENTE','PARCIAL','PAGADO','CANCELADO') NOT NULL DEFAULT 'PENDIENTE',
  CONSTRAINT fk_cargo_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON DELETE RESTRICT,
  CONSTRAINT fk_cargo_cuota FOREIGN KEY (id_cuota) REFERENCES cuota(id_cuota) ON DELETE RESTRICT,
  CONSTRAINT uq_cargo_alumno_cuota_periodo UNIQUE (id_alumno,id_cuota,periodo),
  CONSTRAINT chk_cargo_montos CHECK (monto_original >= 0 AND descuento_aplicado >= 0 AND monto >= 0 AND monto <= monto_original),
  INDEX idx_cargo_alumno_estado (id_alumno,estado,periodo)
) ENGINE=InnoDB;

CREATE TABLE pago (
  id_pago BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  id_usuario_registra BIGINT UNSIGNED NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  monto DECIMAL(10,2) NOT NULL,
  metodo_pago VARCHAR(50) NOT NULL,
  referencia VARCHAR(150) NULL,
  observaciones VARCHAR(255) NULL,
  CONSTRAINT fk_pago_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON DELETE RESTRICT,
  CONSTRAINT fk_pago_usuario FOREIGN KEY (id_usuario_registra) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
  CONSTRAINT chk_pago_monto CHECK (monto > 0),
  INDEX idx_pago_alumno_fecha (id_alumno,fecha)
) ENGINE=InnoDB;

CREATE TABLE aplicacion_pago (
  id_aplicacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_pago BIGINT UNSIGNED NOT NULL,
  id_cargo BIGINT UNSIGNED NOT NULL,
  monto_aplicado DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_aplicacion_pago FOREIGN KEY (id_pago) REFERENCES pago(id_pago) ON DELETE RESTRICT,
  CONSTRAINT fk_aplicacion_cargo FOREIGN KEY (id_cargo) REFERENCES cargo(id_cargo) ON DELETE RESTRICT,
  CONSTRAINT uq_aplicacion_pago_cargo UNIQUE (id_pago,id_cargo),
  CONSTRAINT chk_aplicacion_monto CHECK (monto_aplicado > 0),
  INDEX idx_aplicacion_cargo (id_cargo)
) ENGINE=InnoDB;

-- ------------------------------ CALENDARIO -------------------
CREATE TABLE tipo_evento (
  id_tipo_evento BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB;

CREATE TABLE evento (
  id_evento BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_tipo_evento BIGINT UNSIGNED NOT NULL,
  id_equipo BIGINT UNSIGNED NULL,
  titulo VARCHAR(150) NOT NULL,
  fecha_inicio DATETIME NOT NULL,
  fecha_fin DATETIME NULL,
  descripcion TEXT NULL,
  creado_por BIGINT UNSIGNED NOT NULL,
  CONSTRAINT fk_evento_tipo FOREIGN KEY (id_tipo_evento) REFERENCES tipo_evento(id_tipo_evento) ON DELETE RESTRICT,
  CONSTRAINT fk_evento_equipo FOREIGN KEY (id_equipo) REFERENCES equipo(id_equipo) ON DELETE RESTRICT,
  CONSTRAINT fk_evento_usuario FOREIGN KEY (creado_por) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
  CONSTRAINT chk_evento_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
  INDEX idx_evento_fecha (fecha_inicio,fecha_fin)
) ENGINE=InnoDB;

-- ----------------------------- UNIFORMES ---------------------
CREATE TABLE tipo_uniforme (
  id_tipo_uniforme BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion VARCHAR(255) NULL,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB;

CREATE TABLE prenda (
  id_prenda BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion VARCHAR(255) NULL,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB;

CREATE TABLE talla (
  id_talla BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO'
) ENGINE=InnoDB;

CREATE TABLE inventario_prenda (
  id_inventario BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_prenda BIGINT UNSIGNED NOT NULL,
  id_talla BIGINT UNSIGNED NOT NULL,
  cantidad INT UNSIGNED NOT NULL DEFAULT 0,
  CONSTRAINT fk_inventario_prenda FOREIGN KEY (id_prenda) REFERENCES prenda(id_prenda) ON DELETE RESTRICT,
  CONSTRAINT fk_inventario_talla FOREIGN KEY (id_talla) REFERENCES talla(id_talla) ON DELETE RESTRICT,
  CONSTRAINT uq_inventario_prenda_talla UNIQUE (id_prenda,id_talla)
) ENGINE=InnoDB;

CREATE TABLE pedido_uniforme (
  id_pedido BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_alumno BIGINT UNSIGNED NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  observaciones TEXT NULL,
  creado_por BIGINT UNSIGNED NOT NULL,
  CONSTRAINT fk_pedido_alumno FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno) ON DELETE RESTRICT,
  CONSTRAINT fk_pedido_usuario FOREIGN KEY (creado_por) REFERENCES usuario(id_usuario) ON DELETE RESTRICT,
  INDEX idx_pedido_alumno_fecha (id_alumno,fecha)
) ENGINE=InnoDB;

CREATE TABLE detalle_uniforme (
  id_detalle BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_pedido BIGINT UNSIGNED NOT NULL,
  id_tipo_uniforme BIGINT UNSIGNED NOT NULL,
  nombre_playera VARCHAR(100) NULL COMMENT 'Copia histórica al momento del pedido',
  numero_playera SMALLINT UNSIGNED NULL COMMENT 'Copia histórica al momento del pedido',
  CONSTRAINT fk_du_pedido FOREIGN KEY (id_pedido) REFERENCES pedido_uniforme(id_pedido) ON DELETE CASCADE,
  CONSTRAINT fk_du_tipo FOREIGN KEY (id_tipo_uniforme) REFERENCES tipo_uniforme(id_tipo_uniforme) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE detalle_uniforme_prenda (
  id_detalle_prenda BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_detalle BIGINT UNSIGNED NOT NULL,
  id_prenda BIGINT UNSIGNED NOT NULL,
  id_talla BIGINT UNSIGNED NOT NULL,
  cantidad SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  incluye BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_dup_detalle FOREIGN KEY (id_detalle) REFERENCES detalle_uniforme(id_detalle) ON DELETE CASCADE,
  CONSTRAINT fk_dup_prenda FOREIGN KEY (id_prenda) REFERENCES prenda(id_prenda) ON DELETE RESTRICT,
  CONSTRAINT fk_dup_talla FOREIGN KEY (id_talla) REFERENCES talla(id_talla) ON DELETE RESTRICT,
  CONSTRAINT chk_dup_cantidad CHECK (cantidad > 0),
  CONSTRAINT uq_dup_detalle_prenda_talla UNIQUE (id_detalle,id_prenda,id_talla)
) ENGINE=InnoDB;

-- -------------------------------- BITÁCORA -------------------
CREATE TABLE bitacora (
  id_bitacora BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_usuario BIGINT UNSIGNED NULL,
  fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  accion VARCHAR(100) NOT NULL,
  modulo VARCHAR(100) NOT NULL,
  tabla_afectada VARCHAR(100) NULL,
  id_registro BIGINT UNSIGNED NULL,
  descripcion TEXT NULL,
  ip_origen VARCHAR(45) NULL,
  CONSTRAINT fk_bitacora_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE SET NULL,
  INDEX idx_bitacora_fecha (fecha_hora),
  INDEX idx_bitacora_usuario_fecha (id_usuario,fecha_hora)
) ENGINE=InnoDB;

-- -------------------------- REGLAS / TRIGGERS ----------------
DELIMITER $$

-- Debe existir al menos un administrador, y solo uno activo.
CREATE TRIGGER bi_usuario_un_admin
BEFORE INSERT ON usuario FOR EACH ROW
BEGIN
  IF NEW.rol = 'ADMINISTRADOR' AND NEW.estado = 'ACTIVO'
     AND EXISTS (SELECT 1 FROM usuario WHERE rol='ADMINISTRADOR' AND estado='ACTIVO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Solo puede existir un administrador activo.';
  END IF;
END$$

CREATE TRIGGER bu_usuario_un_admin
BEFORE UPDATE ON usuario FOR EACH ROW
BEGIN
  IF NEW.rol = 'ADMINISTRADOR' AND NEW.estado = 'ACTIVO'
     AND (OLD.rol <> 'ADMINISTRADOR' OR OLD.estado <> 'ACTIVO')
     AND EXISTS (SELECT 1 FROM usuario WHERE rol='ADMINISTRADOR' AND estado='ACTIVO' AND id_usuario <> OLD.id_usuario) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Solo puede existir un administrador activo.';
  END IF;
END$$

-- Evitar mezclar perfil de profesor y administrador en una misma persona.
CREATE TRIGGER bi_usuario_no_admin_profesor
BEFORE INSERT ON usuario FOR EACH ROW
BEGIN
  IF NEW.rol='ADMINISTRADOR' AND EXISTS (
    SELECT 1 FROM profesor p JOIN personal pe ON pe.id_personal=p.id_personal
    JOIN persona per ON per.id_persona=pe.id_persona WHERE per.id_persona=NEW.id_persona
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Una persona no puede ser profesor y administrador.';
  END IF;
  IF NEW.rol='PROFESOR' AND EXISTS (
    SELECT 1 FROM usuario u WHERE u.id_persona=NEW.id_persona AND u.rol='ADMINISTRADOR'
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Una persona no puede ser profesor y administrador.';
  END IF;
END$$

-- Una persona no puede ser profesor y administrador si se cambia el rol.
CREATE TRIGGER bu_usuario_no_admin_profesor
BEFORE UPDATE ON usuario FOR EACH ROW
BEGIN
  IF NEW.rol='ADMINISTRADOR' AND EXISTS (
    SELECT 1 FROM profesor p JOIN personal pe ON pe.id_personal=p.id_personal
    WHERE pe.id_persona=NEW.id_persona
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Una persona no puede ser profesor y administrador.';
  END IF;
  IF NEW.rol='PROFESOR' AND EXISTS (
    SELECT 1 FROM usuario u WHERE u.id_persona=NEW.id_persona AND u.rol='ADMINISTRADOR' AND u.id_usuario<>OLD.id_usuario
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Una persona no puede ser profesor y administrador.';
  END IF;
END$$

-- Garantizar máximo un profesor principal activo por equipo.
CREATE TRIGGER bi_profesor_equipo_principal
BEFORE INSERT ON profesor_equipo FOR EACH ROW
BEGIN
  IF NEW.tipo_participacion='PRINCIPAL' AND NEW.fecha_fin IS NULL AND EXISTS (
    SELECT 1 FROM profesor_equipo WHERE id_equipo=NEW.id_equipo AND tipo_participacion='PRINCIPAL' AND fecha_fin IS NULL
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El equipo ya tiene un profesor principal activo.';
  END IF;
END$$

CREATE TRIGGER bu_profesor_equipo_principal
BEFORE UPDATE ON profesor_equipo FOR EACH ROW
BEGIN
  IF NEW.tipo_participacion='PRINCIPAL' AND NEW.fecha_fin IS NULL AND EXISTS (
    SELECT 1 FROM profesor_equipo WHERE id_equipo=NEW.id_equipo AND tipo_participacion='PRINCIPAL' AND fecha_fin IS NULL AND id_profesor_equipo<>OLD.id_profesor_equipo
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El equipo ya tiene un profesor principal activo.';
  END IF;
END$$

-- Un alumno solo puede tener una asignación principal vigente.
CREATE TRIGGER bi_alumno_equipo_principal
BEFORE INSERT ON alumno_equipo FOR EACH ROW
BEGIN
  IF NEW.tipo_participacion='PRINCIPAL' AND NEW.fecha_fin IS NULL AND EXISTS (
    SELECT 1 FROM alumno_equipo WHERE id_alumno=NEW.id_alumno AND tipo_participacion='PRINCIPAL' AND fecha_fin IS NULL
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El alumno ya tiene un equipo principal vigente.';
  END IF;
END$$

CREATE TRIGGER bu_alumno_equipo_principal
BEFORE UPDATE ON alumno_equipo FOR EACH ROW
BEGIN
  IF NEW.tipo_participacion='PRINCIPAL' AND NEW.fecha_fin IS NULL AND EXISTS (
    SELECT 1 FROM alumno_equipo WHERE id_alumno=NEW.id_alumno AND tipo_participacion='PRINCIPAL' AND fecha_fin IS NULL AND id_alumno_equipo<>OLD.id_alumno_equipo
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El alumno ya tiene un equipo principal vigente.';
  END IF;
END$$

-- Toda asistencia de alumno debe corresponder a un equipo en el que participe
-- (principal o refuerzo) en la fecha del entrenamiento.
CREATE TRIGGER bi_asistencia_equipo
BEFORE INSERT ON asistencia FOR EACH ROW
BEGIN
  DECLARE v_equipo BIGINT UNSIGNED;
  DECLARE v_fecha DATE;
  SELECT id_equipo,fecha INTO v_equipo,v_fecha FROM entrenamiento WHERE id_entrenamiento=NEW.id_entrenamiento;
  IF NOT EXISTS (
    SELECT 1 FROM alumno_equipo ae
    WHERE ae.id_alumno=NEW.id_alumno AND ae.id_equipo=v_equipo
      AND ae.fecha_inicio<=v_fecha AND (ae.fecha_fin IS NULL OR ae.fecha_fin>=v_fecha)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El alumno no pertenece a ese equipo en la fecha del entrenamiento.';
  END IF;
END$$

CREATE TRIGGER bu_asistencia_equipo
BEFORE UPDATE ON asistencia FOR EACH ROW
BEGIN
  DECLARE v_equipo BIGINT UNSIGNED;
  DECLARE v_fecha DATE;
  SELECT id_equipo,fecha INTO v_equipo,v_fecha FROM entrenamiento WHERE id_entrenamiento=NEW.id_entrenamiento;
  IF NOT EXISTS (
    SELECT 1 FROM alumno_equipo ae
    WHERE ae.id_alumno=NEW.id_alumno AND ae.id_equipo=v_equipo
      AND ae.fecha_inicio<=v_fecha AND (ae.fecha_fin IS NULL OR ae.fecha_fin>=v_fecha)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El alumno no pertenece a ese equipo en la fecha del entrenamiento.';
  END IF;
END$$

-- La estadística individual debe corresponder a una convocatoria que participó.
CREATE TRIGGER bi_estadistica_convocatoria
BEFORE INSERT ON estadistica_partido FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM convocatoria c WHERE c.id_partido=NEW.id_partido AND c.id_alumno=NEW.id_alumno AND c.convocado=TRUE AND c.participo=TRUE) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Registra convocatoria y participación antes de guardar estadísticas.';
  END IF;
END$$

CREATE TRIGGER bu_estadistica_convocatoria
BEFORE UPDATE ON estadistica_partido FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM convocatoria c WHERE c.id_partido=NEW.id_partido AND c.id_alumno=NEW.id_alumno AND c.convocado=TRUE AND c.participo=TRUE) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La estadística requiere convocatoria con participación.';
  END IF;
END$$

-- Evaluación finalizada: exige al menos un criterio evaluado en cada uno de los cuatro ámbitos activos.
CREATE PROCEDURE sp_finalizar_evaluacion(IN p_id_evaluacion BIGINT UNSIGNED)
BEGIN
  DECLARE v_total INT DEFAULT 0;
  DECLARE v_faltantes INT DEFAULT 0;
  SELECT COUNT(*) INTO v_total FROM detalle_evaluacion WHERE id_evaluacion=p_id_evaluacion;
  IF v_total=0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La evaluación debe incluir criterios.';
  END IF;
  SELECT COUNT(*) INTO v_faltantes
  FROM tipo_evaluacion te
  WHERE te.estado='ACTIVO' AND NOT EXISTS (
    SELECT 1 FROM criterio_evaluacion ce
    JOIN detalle_evaluacion de ON de.id_criterio=ce.id_criterio
    WHERE ce.id_tipo_evaluacion=te.id_tipo_evaluacion
      AND ce.estado='ACTIVO' AND de.id_evaluacion=p_id_evaluacion
  );
  IF v_faltantes>0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La evaluación debe cubrir Técnico, Táctico, Físico y Mental.';
  END IF;
  UPDATE evaluacion SET estado='FINALIZADA' WHERE id_evaluacion=p_id_evaluacion;
END$$

-- Solo un usuario con rol ADMINISTRADOR puede registrar pagos.
CREATE TRIGGER bi_pago_solo_admin
BEFORE INSERT ON pago FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario=NEW.id_usuario_registra AND rol='ADMINISTRADOR' AND estado='ACTIVO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Solo un administrador activo puede registrar pagos.';
  END IF;
END$$

CREATE TRIGGER bu_pago_solo_admin
BEFORE UPDATE ON pago FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario=NEW.id_usuario_registra AND rol='ADMINISTRADOR' AND estado='ACTIVO') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El pago debe quedar registrado por un administrador activo.';
  END IF;
END$$

-- Solo administrador o responsable puede cargar documentos en la versión inicial.
CREATE TRIGGER bi_documento_permisos_carga
BEFORE INSERT ON documento FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario=NEW.id_usuario_carga AND estado='ACTIVO' AND rol IN ('ADMINISTRADOR','RESPONSABLE')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Solo administrador o responsable activo puede cargar documentos.';
  END IF;
END$$

-- Las evaluaciones solo pueden ser registradas por administrador o profesor activo.
CREATE TRIGGER bi_evaluacion_evaluador
BEFORE INSERT ON evaluacion FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario=NEW.id_usuario_evaluador AND estado='ACTIVO' AND rol IN ('ADMINISTRADOR','PROFESOR')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Solo administrador o profesor activo puede evaluar.';
  END IF;
END$$

CREATE TRIGGER bu_evaluacion_evaluador
BEFORE UPDATE ON evaluacion FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM usuario WHERE id_usuario=NEW.id_usuario_evaluador AND estado='ACTIVO' AND rol IN ('ADMINISTRADOR','PROFESOR')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El evaluador debe ser administrador o profesor activo.';
  END IF;
END$$

-- Pago: al registrar una aplicación, impedir exceder el pago o el saldo del cargo.
CREATE TRIGGER bi_aplicacion_pago_validar
BEFORE INSERT ON aplicacion_pago FOR EACH ROW
BEGIN
  DECLARE v_pago DECIMAL(10,2);
  DECLARE v_aplicado DECIMAL(10,2);
  DECLARE v_cargo DECIMAL(10,2);
  DECLARE v_cargo_aplicado DECIMAL(10,2);
  DECLARE v_alumno_pago BIGINT UNSIGNED;
  DECLARE v_alumno_cargo BIGINT UNSIGNED;
  SELECT monto,id_alumno INTO v_pago,v_alumno_pago FROM pago WHERE id_pago=NEW.id_pago;
  SELECT monto,id_alumno INTO v_cargo,v_alumno_cargo FROM cargo WHERE id_cargo=NEW.id_cargo;
  IF v_alumno_pago<>v_alumno_cargo THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El pago y el cargo deben corresponder al mismo alumno.';
  END IF;
  SELECT COALESCE(SUM(monto_aplicado),0) INTO v_aplicado FROM aplicacion_pago WHERE id_pago=NEW.id_pago;
  SELECT COALESCE(SUM(monto_aplicado),0) INTO v_cargo_aplicado FROM aplicacion_pago WHERE id_cargo=NEW.id_cargo;
  IF v_aplicado + NEW.monto_aplicado > v_pago THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La aplicación excede el monto del pago.';
  END IF;
  IF v_cargo_aplicado + NEW.monto_aplicado > v_cargo THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La aplicación excede el saldo del cargo.';
  END IF;
END$$

CREATE TRIGGER bu_aplicacion_pago_validar
BEFORE UPDATE ON aplicacion_pago FOR EACH ROW
BEGIN
  DECLARE v_pago DECIMAL(10,2);
  DECLARE v_aplicado DECIMAL(10,2);
  DECLARE v_cargo DECIMAL(10,2);
  DECLARE v_cargo_aplicado DECIMAL(10,2);
  DECLARE v_alumno_pago BIGINT UNSIGNED;
  DECLARE v_alumno_cargo BIGINT UNSIGNED;
  SELECT monto,id_alumno INTO v_pago,v_alumno_pago FROM pago WHERE id_pago=NEW.id_pago;
  SELECT monto,id_alumno INTO v_cargo,v_alumno_cargo FROM cargo WHERE id_cargo=NEW.id_cargo;
  IF v_alumno_pago<>v_alumno_cargo THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='El pago y el cargo deben corresponder al mismo alumno.';
  END IF;
  SELECT COALESCE(SUM(monto_aplicado),0) INTO v_aplicado FROM aplicacion_pago WHERE id_pago=NEW.id_pago AND id_aplicacion<>OLD.id_aplicacion;
  SELECT COALESCE(SUM(monto_aplicado),0) INTO v_cargo_aplicado FROM aplicacion_pago WHERE id_cargo=NEW.id_cargo AND id_aplicacion<>OLD.id_aplicacion;
  IF v_aplicado + NEW.monto_aplicado > v_pago OR v_cargo_aplicado + NEW.monto_aplicado > v_cargo THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='La aplicación supera el monto disponible.';
  END IF;
END$$

CREATE PROCEDURE sp_actualizar_estado_cargo(IN p_id_cargo BIGINT UNSIGNED)
BEGIN
  DECLARE v_monto DECIMAL(10,2);
  DECLARE v_aplicado DECIMAL(10,2);
  DECLARE v_estado VARCHAR(20);
  SELECT monto,estado INTO v_monto,v_estado FROM cargo WHERE id_cargo=p_id_cargo;
  SELECT COALESCE(SUM(monto_aplicado),0) INTO v_aplicado FROM aplicacion_pago WHERE id_cargo=p_id_cargo;
  IF v_estado <> 'CANCELADO' THEN
    UPDATE cargo SET estado = CASE
      WHEN v_aplicado=0 THEN 'PENDIENTE'
      WHEN v_aplicado < v_monto THEN 'PARCIAL'
      ELSE 'PAGADO'
    END WHERE id_cargo=p_id_cargo;
  END IF;
END$$

CREATE TRIGGER ai_aplicacion_pago_estado
AFTER INSERT ON aplicacion_pago FOR EACH ROW
BEGIN
  CALL sp_actualizar_estado_cargo(NEW.id_cargo);
END$$

CREATE TRIGGER au_aplicacion_pago_estado
AFTER UPDATE ON aplicacion_pago FOR EACH ROW
BEGIN
  CALL sp_actualizar_estado_cargo(OLD.id_cargo);
  IF NEW.id_cargo<>OLD.id_cargo THEN CALL sp_actualizar_estado_cargo(NEW.id_cargo); END IF;
END$$

CREATE TRIGGER ad_aplicacion_pago_estado
AFTER DELETE ON aplicacion_pago FOR EACH ROW
BEGIN
  CALL sp_actualizar_estado_cargo(OLD.id_cargo);
END$$

-- Crear cargos mensuales de manera idempotente para todos los alumnos activos.
-- Se recomienda ejecutarlo mediante un evento programado externo/cron mensual.
CREATE PROCEDURE sp_generar_cargos_mensuales(IN p_periodo CHAR(7), IN p_fecha_vencimiento DATE)
BEGIN
  DECLARE v_fecha_periodo DATE;
  SET v_fecha_periodo = STR_TO_DATE(CONCAT(p_periodo,'-01'),'%Y-%m-%d');
  IF v_fecha_periodo IS NULL OR DATE_FORMAT(v_fecha_periodo,'%Y-%m') <> p_periodo THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Periodo inválido; usar YYYY-MM.';
  END IF;

  INSERT INTO cargo (id_alumno,id_cuota,periodo,fecha_generacion,fecha_vencimiento,monto_original,descuento_aplicado,monto)
  SELECT a.id_alumno, q.id_cuota, p_periodo, CURRENT_DATE, p_fecha_vencimiento,
         q.monto,
         LEAST(q.monto, COALESCE((
           SELECT SUM(CASE d.tipo WHEN 'PORCENTAJE' THEN q.monto*d.valor/100 ELSE d.valor END)
           FROM alumno_descuento ad JOIN descuento d ON d.id_descuento=ad.id_descuento
           WHERE ad.id_alumno=a.id_alumno AND d.estado='ACTIVO'
             AND ad.fecha_inicio<=v_fecha_periodo
             AND (ad.fecha_fin IS NULL OR ad.fecha_fin>=v_fecha_periodo)
         ),0)),
         GREATEST(0, q.monto - LEAST(q.monto, COALESCE((
           SELECT SUM(CASE d.tipo WHEN 'PORCENTAJE' THEN q.monto*d.valor/100 ELSE d.valor END)
           FROM alumno_descuento ad JOIN descuento d ON d.id_descuento=ad.id_descuento
           WHERE ad.id_alumno=a.id_alumno AND d.estado='ACTIVO'
             AND ad.fecha_inicio<=v_fecha_periodo
             AND (ad.fecha_fin IS NULL OR ad.fecha_fin>=v_fecha_periodo)
         ),0)))
  FROM alumno a
  JOIN cuota q ON q.id_concepto = (SELECT cp.id_concepto FROM concepto_pago cp WHERE cp.nombre='Mensualidad' LIMIT 1)
  WHERE a.estado='ACTIVO' AND q.estado='ACTIVA'
    AND q.fecha_inicio <= LAST_DAY(v_fecha_periodo)
    AND (q.fecha_fin IS NULL OR q.fecha_fin >= v_fecha_periodo)
  ON DUPLICATE KEY UPDATE id_cargo=id_cargo;
END$$

-- Vista de saldo de cargos (saldo nunca negativo).
CREATE VIEW vw_saldo_cargo AS
SELECT c.id_cargo,c.id_alumno,c.id_cuota,c.periodo,c.monto_original,c.descuento_aplicado,c.monto,
       COALESCE(SUM(ap.monto_aplicado),0) AS total_aplicado,
       GREATEST(0,c.monto-COALESCE(SUM(ap.monto_aplicado),0)) AS saldo_pendiente,
       c.estado
FROM cargo c LEFT JOIN aplicacion_pago ap ON ap.id_cargo=c.id_cargo
GROUP BY c.id_cargo,c.id_alumno,c.id_cuota,c.periodo,c.monto_original,c.descuento_aplicado,c.monto,c.estado;

CREATE VIEW vw_resumen_financiero_alumno AS
SELECT a.id_alumno,
       COALESCE(SUM(CASE WHEN c.estado<>'CANCELADO' THEN s.saldo_pendiente ELSE 0 END),0) AS total_pendiente,
       (SELECT MAX(p.fecha) FROM pago p WHERE p.id_alumno=a.id_alumno) AS ultimo_pago,
       (SELECT MIN(c2.fecha_vencimiento) FROM cargo c2 JOIN vw_saldo_cargo s2 ON s2.id_cargo=c2.id_cargo
        WHERE c2.id_alumno=a.id_alumno AND c2.estado IN ('PENDIENTE','PARCIAL') AND s2.saldo_pendiente>0
          AND c2.fecha_vencimiento IS NOT NULL) AS proximo_vencimiento
FROM alumno a LEFT JOIN vw_saldo_cargo s ON s.id_alumno=a.id_alumno
LEFT JOIN cargo c ON c.id_cargo=s.id_cargo
GROUP BY a.id_alumno;

CREATE VIEW vw_documentos_faltantes AS
SELECT a.id_alumno, td.id_tipo_documento, td.nombre AS tipo_documento
FROM alumno a CROSS JOIN tipo_documento td
WHERE a.estado='ACTIVO' AND td.estado='ACTIVO'
  AND NOT EXISTS (
    SELECT 1 FROM documento d WHERE d.id_alumno=a.id_alumno AND d.id_tipo_documento=td.id_tipo_documento AND d.estado='ACTIVO'
  );

CREATE VIEW vw_estadisticas_alumno_periodo AS
SELECT ep.id_alumno,
       DATE_FORMAT(p.fecha,'%Y-%m') AS periodo,
       COUNT(DISTINCT p.id_partido) AS partidos_registrados,
       SUM(ep.goles) AS goles,
       SUM(ep.asistencias) AS asistencias,
       SUM(ep.minutos) AS minutos,
       SUM(ep.tarjetas_amarillas) AS tarjetas_amarillas,
       SUM(ep.tarjetas_rojas) AS tarjetas_rojas
FROM estadistica_partido ep JOIN partido p ON p.id_partido=ep.id_partido
WHERE p.estado='JUGADO'
GROUP BY ep.id_alumno,DATE_FORMAT(p.fecha,'%Y-%m');

-- ----------------------------- DATOS CATÁLOGO ----------------
INSERT INTO tipo_evaluacion(nombre) VALUES ('TECNICO'),('TACTICO'),('FISICO'),('MENTAL');

INSERT INTO criterio_evaluacion(id_tipo_evaluacion,nombre)
SELECT te.id_tipo_evaluacion, criterios.nombre
FROM tipo_evaluacion te
JOIN (
  SELECT 'TECNICO' AS tipo,'Pase' AS nombre UNION ALL
  SELECT 'TECNICO','Tiro' UNION ALL
  SELECT 'TECNICO','Cabeceo' UNION ALL
  SELECT 'TECNICO','Control' UNION ALL
  SELECT 'TACTICO','Posicionamiento' UNION ALL
  SELECT 'TACTICO','Marcaje' UNION ALL
  SELECT 'TACTICO','Juego en equipo' UNION ALL
  SELECT 'FISICO','Velocidad' UNION ALL
  SELECT 'FISICO','Resistencia' UNION ALL
  SELECT 'FISICO','Fuerza' UNION ALL
  SELECT 'FISICO','Coordinación' UNION ALL
  SELECT 'MENTAL','Concentración' UNION ALL
  SELECT 'MENTAL','Disciplina' UNION ALL
  SELECT 'MENTAL','Comunicación'
) AS criterios ON criterios.tipo=te.nombre;

INSERT INTO tipo_documento(nombre,descripcion) VALUES
 ('CURP','Documento de identificación del alumno'),
 ('ACTA DE NACIMIENTO','Acta de nacimiento'),
 ('CREDENCIAL','Credencial o identificación');

INSERT INTO tipo_partido(nombre) VALUES ('AMISTOSO'),('TORNEO'),('LIGA'),('ELIMINATORIA');

INSERT INTO tipo_evento(nombre) VALUES ('ENTRENAMIENTO'),('JUNTA'),('PARTIDO'),('EVENTO ALCALDIA'),('OTRO');

INSERT INTO tipo_uniforme(nombre,descripcion) VALUES
 ('LOCAL','Uniforme de local'),('VISITANTE','Uniforme de visitante'),
 ('ENTRENAMIENTO','Uniforme de entrenamiento'),('PORTERO','Uniforme de portero');

INSERT INTO prenda(nombre,descripcion) VALUES
 ('PLAYERA','Playera deportiva'),('SHORT','Short deportivo'),('CALCETAS','Calcetas deportivas');

INSERT INTO talla(nombre) VALUES ('CH'),('M'),('G'),('XG');

INSERT INTO concepto_pago(nombre,descripcion) VALUES ('Mensualidad','Cuota mensual de la academia');

-- -------------------------------------------------------------
-- CONFIGURACIÓN INICIAL IMPORTANTE
-- 1) Crear la persona/usuario administrador desde un proceso seguro.
-- 2) contrasena_hash debe generarse en backend (Argon2id o bcrypt).
-- 3) Insertar al menos una cuota activa para el concepto Mensualidad.
-- 4) Configurar MySQL Event Scheduler o cron para llamar cada mes:
--    CALL sp_generar_cargos_mensuales(DATE_FORMAT(CURRENT_DATE,'%Y-%m'), LAST_DAY(CURRENT_DATE));
-- 5) No hay credenciales predeterminadas por seguridad.
-- -------------------------------------------------------------
