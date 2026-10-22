-- ============================================================
-- ACADEMIA LOBOS - BASE DE DATOS v1.0
-- Alcance: Módulo de Inicio de Sesión
-- MySQL 8.0+
--
-- Seguridad:
--   1) Seguridad de aplicación: usuario, rol, permiso, rol_permiso.
--   2) Seguridad MySQL: roles nativos y cuentas con GRANT.
--
-- Contraseñas:
--   Las cuentas de aplicación usan contrasena_hash.
--   Para la entrega se incluyen cuentas de demostración con NULL
--   para que el backend pueda asignar un hash posteriormente.
--   NO se almacena la contraseña en texto plano.
-- ============================================================

DROP DATABASE IF EXISTS academia_lobos;
CREATE DATABASE academia_lobos
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE academia_lobos;

-- ============================================================
-- 1. PERSONAS
-- Información mínima necesaria para relacionar una cuenta
-- con una persona.
-- ============================================================

CREATE TABLE persona (
    id_persona BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    apellido_paterno VARCHAR(80) NOT NULL,
    apellido_materno VARCHAR(80) NULL,
    correo VARCHAR(150) NULL,
    telefono VARCHAR(25) NULL,
    estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uq_persona_correo UNIQUE (correo)
) ENGINE=InnoDB;

-- ============================================================
-- 2. ROLES DE LA APLICACIÓN
-- ============================================================

CREATE TABLE rol (
    id_rol BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(40) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    descripcion VARCHAR(255) NULL,
    estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',

    CONSTRAINT uq_rol_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

CREATE TABLE permiso (
    id_permiso BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(80) NOT NULL,
    modulo VARCHAR(80) NOT NULL,
    accion VARCHAR(40) NOT NULL,
    descripcion VARCHAR(255) NULL,

    CONSTRAINT uq_permiso_codigo UNIQUE (codigo)
) ENGINE=InnoDB;

CREATE TABLE rol_permiso (
    id_rol BIGINT UNSIGNED NOT NULL,
    id_permiso BIGINT UNSIGNED NOT NULL,

    PRIMARY KEY (id_rol, id_permiso),

    CONSTRAINT fk_rol_permiso_rol
        FOREIGN KEY (id_rol)
        REFERENCES rol(id_rol)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_rol_permiso_permiso
        FOREIGN KEY (id_permiso)
        REFERENCES permiso(id_permiso)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 3. USUARIOS DE LA APLICACIÓN
--
-- La contraseña NO se almacena en texto plano.
-- contrasena_hash queda preparada para recibir un hash generado
-- por el backend (por ejemplo Argon2id o bcrypt).
-- ============================================================

CREATE TABLE usuario (
    id_usuario BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_persona BIGINT UNSIGNED NOT NULL,
    id_rol BIGINT UNSIGNED NOT NULL,

    nombre_usuario VARCHAR(50) NOT NULL,
    contrasena_hash VARCHAR(255) NULL,

    estado ENUM('ACTIVO','INACTIVO','BLOQUEADO')
        NOT NULL DEFAULT 'ACTIVO',

    intentos_fallidos TINYINT UNSIGNED NOT NULL DEFAULT 0,
    ultimo_acceso DATETIME NULL,

    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uq_usuario_nombre UNIQUE (nombre_usuario),

    CONSTRAINT fk_usuario_persona
        FOREIGN KEY (id_persona)
        REFERENCES persona(id_persona)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_usuario_rol
        FOREIGN KEY (id_rol)
        REFERENCES rol(id_rol)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    INDEX idx_usuario_estado (estado),
    INDEX idx_usuario_rol (id_rol)
) ENGINE=InnoDB;

-- ============================================================
-- 4. DATOS MÍNIMOS DE PERFIL
-- Se conservan para representar los perfiles del login.
-- ============================================================

CREATE TABLE alumno (
    id_alumno BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_persona BIGINT UNSIGNED NOT NULL,
    numero_boleta VARCHAR(30) NULL,
    fecha_ingreso DATE NULL,

    CONSTRAINT uq_alumno_persona UNIQUE (id_persona),
    CONSTRAINT uq_alumno_boleta UNIQUE (numero_boleta),

    CONSTRAINT fk_alumno_persona
        FOREIGN KEY (id_persona)
        REFERENCES persona(id_persona)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE personal (
    id_personal BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_persona BIGINT UNSIGNED NOT NULL,
    puesto VARCHAR(100) NOT NULL,
    fecha_ingreso DATE NULL,

    CONSTRAINT uq_personal_persona UNIQUE (id_persona),

    CONSTRAINT fk_personal_persona
        FOREIGN KEY (id_persona)
        REFERENCES persona(id_persona)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE responsable (
    id_responsable BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_persona BIGINT UNSIGNED NOT NULL,
    parentesco_principal ENUM('PADRE','MADRE','TUTOR') NOT NULL,

    CONSTRAINT uq_responsable_persona UNIQUE (id_persona),

    CONSTRAINT fk_responsable_persona
        FOREIGN KEY (id_persona)
        REFERENCES persona(id_persona)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 5. CATÁLOGOS DE ROLES Y PERMISOS
-- ============================================================

INSERT INTO rol (codigo, nombre, descripcion) VALUES
('ADMINISTRADOR', 'Administrador',
 'Gestiona el sistema y tiene acceso administrativo.'),
('PROFESOR', 'Profesor',
 'Accede a las funciones correspondientes al personal deportivo.'),
('RESPONSABLE', 'Padre/Madre/Tutor',
 'Consulta información de los alumnos que tiene asociados.'),
('ALUMNO', 'Alumno',
 'Consulta su propia información.');

INSERT INTO permiso (codigo, modulo, accion, descripcion) VALUES
('LOGIN.INICIAR', 'AUTENTICACION', 'INICIAR_SESION',
 'Permite iniciar sesión.'),
('LOGIN.CERRAR', 'AUTENTICACION', 'CERRAR_SESION',
 'Permite cerrar sesión.'),
('USUARIO.CONSULTAR', 'USUARIOS', 'CONSULTAR',
 'Consultar información básica de usuarios.'),
('USUARIO.GESTIONAR', 'USUARIOS', 'GESTIONAR',
 'Crear, modificar, activar e inactivar usuarios.'),
('ROL.CONSULTAR', 'SEGURIDAD', 'CONSULTAR',
 'Consultar roles.'),
('ROL.GESTIONAR', 'SEGURIDAD', 'GESTIONAR',
 'Administrar roles y permisos.');

-- Todos pueden iniciar/cerrar sesión.
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM rol r
CROSS JOIN permiso p
WHERE p.codigo IN ('LOGIN.INICIAR', 'LOGIN.CERRAR');

-- Solo administrador gestiona usuarios y seguridad.
INSERT INTO rol_permiso (id_rol, id_permiso)
SELECT r.id_rol, p.id_permiso
FROM rol r
CROSS JOIN permiso p
WHERE r.codigo = 'ADMINISTRADOR'
  AND p.codigo IN (
      'USUARIO.CONSULTAR',
      'USUARIO.GESTIONAR',
      'ROL.CONSULTAR',
      'ROL.GESTIONAR'
  );

-- ============================================================
-- 6. TRIGGER: REGLA DE NEGOCIO
-- Solo puede existir un administrador activo.
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_unico_administrador_activo
BEFORE INSERT ON usuario
FOR EACH ROW
BEGIN
    DECLARE v_codigo_rol VARCHAR(40);

    SELECT codigo
      INTO v_codigo_rol
      FROM rol
     WHERE id_rol = NEW.id_rol;

    IF NEW.estado = 'ACTIVO'
       AND v_codigo_rol = 'ADMINISTRADOR'
       AND EXISTS (
           SELECT 1
             FROM usuario u
             JOIN rol r ON r.id_rol = u.id_rol
            WHERE r.codigo = 'ADMINISTRADOR'
              AND u.estado = 'ACTIVO'
       )
    THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Solo puede existir un administrador activo.';
    END IF;
END$$

CREATE TRIGGER trg_unico_administrador_activo_update
BEFORE UPDATE ON usuario
FOR EACH ROW
BEGIN
    DECLARE v_codigo_rol VARCHAR(40);

    SELECT codigo
      INTO v_codigo_rol
      FROM rol
     WHERE id_rol = NEW.id_rol;

    IF NEW.estado = 'ACTIVO'
       AND v_codigo_rol = 'ADMINISTRADOR'
       AND (
            OLD.id_rol <> NEW.id_rol
            OR OLD.estado <> NEW.estado
       )
       AND EXISTS (
           SELECT 1
             FROM usuario u
             JOIN rol r ON r.id_rol = u.id_rol
            WHERE r.codigo = 'ADMINISTRADOR'
              AND u.estado = 'ACTIVO'
              AND u.id_usuario <> OLD.id_usuario
       )
    THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Solo puede existir un administrador activo.';
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- 7. CUENTAS DE DEMOSTRACIÓN
--
-- IMPORTANTE:
-- contrasena_hash = NULL intencionalmente.
-- El backend debe generar y guardar el hash antes de habilitar
-- la autenticación real.
-- ============================================================

INSERT INTO persona
(nombre, apellido_paterno, apellido_materno, correo)
VALUES
('Demo', 'Administrador', NULL, 'admin.demo@academialobos.local'),
('Demo', 'Profesor', NULL, 'profesor.demo@academialobos.local'),
('Demo', 'Responsable', NULL, 'responsable.demo@academialobos.local'),
('Demo', 'Alumno', NULL, 'alumno.demo@academialobos.local');

INSERT INTO personal (id_persona, puesto, fecha_ingreso)
SELECT id_persona, 'Profesor', CURRENT_DATE
FROM persona
WHERE correo = 'profesor.demo@academialobos.local';

INSERT INTO responsable (id_persona, parentesco_principal)
SELECT id_persona, 'MADRE'
FROM persona
WHERE correo = 'responsable.demo@academialobos.local';

INSERT INTO alumno (id_persona, numero_boleta, fecha_ingreso)
SELECT id_persona, 'DEMO-001', CURRENT_DATE
FROM persona
WHERE correo = 'alumno.demo@academialobos.local';

INSERT INTO usuario
(id_persona, id_rol, nombre_usuario, contrasena_hash, estado)
SELECT
    p.id_persona,
    r.id_rol,
    'admin_demo',
    NULL,
    'ACTIVO'
FROM persona p
JOIN rol r ON r.codigo = 'ADMINISTRADOR'
WHERE p.correo = 'admin.demo@academialobos.local';

INSERT INTO usuario
(id_persona, id_rol, nombre_usuario, contrasena_hash, estado)
SELECT
    p.id_persona,
    r.id_rol,
    'profesor_demo',
    NULL,
    'ACTIVO'
FROM persona p
JOIN rol r ON r.codigo = 'PROFESOR'
WHERE p.correo = 'profesor.demo@academialobos.local';

INSERT INTO usuario
(id_persona, id_rol, nombre_usuario, contrasena_hash, estado)
SELECT
    p.id_persona,
    r.id_rol,
    'responsable_demo',
    NULL,
    'ACTIVO'
FROM persona p
JOIN rol r ON r.codigo = 'RESPONSABLE'
WHERE p.correo = 'responsable.demo@academialobos.local';

INSERT INTO usuario
(id_persona, id_rol, nombre_usuario, contrasena_hash, estado)
SELECT
    p.id_persona,
    r.id_rol,
    'alumno_demo',
    NULL,
    'ACTIVO'
FROM persona p
JOIN rol r ON r.codigo = 'ALUMNO'
WHERE p.correo = 'alumno.demo@academialobos.local';

-- ============================================================
-- 8. ROLES NATIVOS DE MYSQL
--
-- Estos roles controlan el acceso a nivel de base de datos.
-- Son independientes de los roles de la aplicación.
-- ============================================================

CREATE ROLE IF NOT EXISTS 'lobos_db_admin';
CREATE ROLE IF NOT EXISTS 'lobos_db_login';
CREATE ROLE IF NOT EXISTS 'lobos_db_consulta';

-- Administrador: acceso completo a la base.
GRANT ALL PRIVILEGES
ON academia_lobos.*
TO 'lobos_db_admin';

-- Login: acceso mínimo para consultar usuarios/roles durante
-- la autenticación. La comparación del hash debe hacerse
-- preferentemente desde el backend.
GRANT SELECT
ON academia_lobos.usuario
TO 'lobos_db_login';

GRANT SELECT
ON academia_lobos.persona
TO 'lobos_db_login';

GRANT SELECT
ON academia_lobos.rol
TO 'lobos_db_login';

GRANT SELECT
ON academia_lobos.permiso
TO 'lobos_db_login';

GRANT SELECT
ON academia_lobos.rol_permiso
TO 'lobos_db_login';

-- Consulta: solamente información básica no sensible.
GRANT SELECT
ON academia_lobos.persona
TO 'lobos_db_consulta';

GRANT SELECT
ON academia_lobos.usuario
TO 'lobos_db_consulta';

GRANT SELECT
ON academia_lobos.rol
TO 'lobos_db_consulta';

-- ============================================================
-- 9. CUENTAS NATIVAS DE MYSQL PARA DEMOSTRACIÓN
--
-- Las contraseñas aquí son de demostración del servidor MySQL.
-- Cambiarlas antes de cualquier uso real.
-- ============================================================

CREATE USER IF NOT EXISTS
    'lobos_admin_demo'@'localhost'
    IDENTIFIED BY 'Cambiar_Admin_2026!';

CREATE USER IF NOT EXISTS
    'lobos_login_demo'@'localhost'
    IDENTIFIED BY 'Cambiar_Login_2026!';

CREATE USER IF NOT EXISTS
    'lobos_consulta_demo'@'localhost'
    IDENTIFIED BY 'Cambiar_Consulta_2026!';

GRANT 'lobos_db_admin'
TO 'lobos_admin_demo'@'localhost';

GRANT 'lobos_db_login'
TO 'lobos_login_demo'@'localhost';

GRANT 'lobos_db_consulta'
TO 'lobos_consulta_demo'@'localhost';

SET DEFAULT ROLE 'lobos_db_admin'
TO 'lobos_admin_demo'@'localhost';

SET DEFAULT ROLE 'lobos_db_login'
TO 'lobos_login_demo'@'localhost';

SET DEFAULT ROLE 'lobos_db_consulta'
TO 'lobos_consulta_demo'@'localhost';

-- ============================================================
-- 10. CONSULTAS DE COMPROBACIÓN
-- ============================================================

-- Usuarios de la aplicación:
-- SELECT
--     u.id_usuario,
--     u.nombre_usuario,
--     r.codigo AS rol,
--     u.estado
-- FROM usuario u
-- JOIN rol r ON r.id_rol = u.id_rol;

-- Permisos por rol:
-- SELECT
--     r.codigo AS rol,
--     p.codigo AS permiso
-- FROM rol_permiso rp
-- JOIN rol r ON r.id_rol = rp.id_rol
-- JOIN permiso p ON p.id_permiso = rp.id_permiso
-- ORDER BY r.codigo, p.codigo;

-- Privilegios de MySQL:
-- SHOW GRANTS FOR 'lobos_admin_demo'@'localhost';
-- SHOW GRANTS FOR 'lobos_login_demo'@'localhost';
-- SHOW GRANTS FOR 'lobos_consulta_demo'@'localhost';
-- Ejecutar una vez en MySQL con una cuenta administradora.
-- Permisos mínimos para iniciar sesión, cambiar la contraseña propia
-- y administrar personas/cuentas desde el panel de administrador.
GRANT UPDATE (contrasena_hash, nombre_usuario, id_rol)
ON academia_lobos.usuario TO 'lobos_login_demo'@'localhost';
GRANT INSERT ON academia_lobos.persona TO 'lobos_login_demo'@'localhost';
GRANT INSERT ON academia_lobos.usuario TO 'lobos_login_demo'@'localhost';
GRANT INSERT ON academia_lobos.alumno TO 'lobos_login_demo'@'localhost';
GRANT INSERT ON academia_lobos.personal TO 'lobos_login_demo'@'localhost';
GRANT INSERT ON academia_lobos.responsable TO 'lobos_login_demo'@'localhost';

SELECT u.nombre_usuario, r.nombre AS rol, u.estado,
       IF(u.contrasena_hash IS NULL, 'SIN HASH', 'TIENE HASH') AS contrasena
FROM usuario u
JOIN rol r ON r.id_rol = u.id_rol
WHERE u.nombre_usuario = 'academia_lobos';


SELECT
    u.id_usuario,
    u.nombre_usuario AS usuario,
    r.nombre AS rol,
    u.estado,
    p.nombre,
    p.apellido_paterno,
    p.apellido_materno,
    p.correo,
    CASE
        WHEN u.contrasena_hash IS NULL THEN 'Sin contraseña'
        ELSE 'Contraseña guardada como hash'
    END AS estado_contrasena
FROM usuario u
JOIN rol r ON r.id_rol = u.id_rol
JOIN persona p ON p.id_persona = u.id_persona
ORDER BY u.id_usuario;
-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
