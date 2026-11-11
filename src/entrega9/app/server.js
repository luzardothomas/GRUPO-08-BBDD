// ============================================================
// Aplicación de la Entrega 9 (TP Mundial 2026, Bases de Datos Aplicada)
//
// Servidor Node.js + Express. No tiene lógica de negocio ni validaciones propias: cada operación ejecuta un
// procedimiento almacenado de las Entregas 5, 6, 7 y 8 y devuelve tal cual el mensaje de error del SP (THROW).
// Usa dos usuarios de la Entrega 8, cada uno con su rol (nunca sa):
//
//   usr_gestor_publicidad (rol_gestor_publicidad)  ABM de anunciantes
//     Alta            publicidad.anunciante_insertar
//     Modificación    publicidad.anunciante_modificar
//     Baja            publicidad.anunciante_eliminar
//     Consulta        publicidad.consultar_anunciante   (contacto descifrado)
//
//   usr_administrador (rol_administrador)           importación de archivos y reportes XML
//     Importación     SP importar_* de la Entrega 6 (reciben la ruta del archivo; el resumen del lote vuelve del SP)
//     Reportes XML    evento.reporte_goleadores y plantel.reporte_plantillas (Entrega 7); el XML se guarda en un archivo
// ============================================================
const fs = require('fs');
const os = require('os');
const path = require('path');
const express = require('express');
const sql = require('mssql');

// ---------- Configuración: variables de entorno o config.local.json (que no se versiona) ----------
let archivo = {};
try { archivo = JSON.parse(fs.readFileSync(path.join(__dirname, 'config.local.json'), 'utf8')); } catch (e) { /* sin archivo */ }
const dato = (nombre, porDefecto) => process.env[nombre] || archivo[nombre] || porDefecto;

const conexion = (usuario, contrasenia) => ({
  server: dato('DB_SERVER', 'localhost'),
  port: dato('DB_INSTANCE', '') ? undefined : Number(dato('DB_PORT', 1433)),
  database: dato('DB_NAME', 'mundial_2026'),
  user: usuario,
  password: contrasenia,
  options: { encrypt: false, trustServerCertificate: true, instanceName: dato('DB_INSTANCE', '') || undefined },
  pool: { max: 5, min: 0, idleTimeoutMillis: 30000 }
});

const USUARIO_ABM = dato('DB_USER', 'usr_gestor_publicidad');
const USUARIO_ADMIN = dato('DB_ADMIN_USER', 'usr_administrador');

// Carpeta donde la aplicación deja los archivos subidos para que SQL Server los lea (BULK / OPENROWSET leen del
// disco del servidor, no del navegador). Tiene que existir en la máquina de SQL Server y ser legible por su servicio.
// IMPORT_SQL_DIR es la misma carpeta vista desde SQL Server, por si la ruta es distinta (por ejemplo, un volumen).
const DIR_IMPORTACION = dato('IMPORT_DIR', os.platform() === 'win32' ? 'C:\\Users\\Public\\mundial_importaciones' : path.join(os.tmpdir(), 'mundial_importaciones'));
const DIR_IMPORTACION_SQL = dato('IMPORT_SQL_DIR', DIR_IMPORTACION);
const DIR_REPORTES = dato('REPORT_DIR', path.join(__dirname, 'reportes'));
fs.mkdirSync(DIR_IMPORTACION, { recursive: true });
fs.mkdirSync(DIR_REPORTES, { recursive: true });

if (!dato('DB_PASSWORD')) {
  console.error('Falta DB_PASSWORD (variable de entorno o config.local.json) con la contraseña de ' + USUARIO_ABM + '.');
  process.exit(1);
}

// ---------- Conexiones ----------
// El administrador se conecta recién cuando se usa (importación o reportes): el ABM funciona aunque falte.
const poolAbm = new sql.ConnectionPool(conexion(USUARIO_ABM, dato('DB_PASSWORD')));
const poolAbmListo = poolAbm.connect();
let poolAdminListo = null;
function poolAdmin() {
  if (!dato('DB_ADMIN_PASSWORD')) {
    return Promise.reject(Object.assign(new Error('Falta DB_ADMIN_PASSWORD (contraseña de ' + USUARIO_ADMIN + ') para importar y generar reportes.'), { sinConfigurar: true }));
  }
  if (!poolAdminListo) {
    const pool = new sql.ConnectionPool(conexion(USUARIO_ADMIN, dato('DB_ADMIN_PASSWORD')));
    poolAdminListo = pool.connect().catch(err => { poolAdminListo = null; throw err; });
  }
  return poolAdminListo;
}

// Los errores que lanzan los SP (THROW 5xxxx) son de validación: se devuelven con 400 y el texto original.
function responderError(res, err) {
  const esValidacion = err.number >= 50000 && err.number < 60000;
  res.status(esValidacion ? 400 : 500).json({ error: err.message, numero: err.number || null });
}

const texto = valor => (valor === undefined || valor === null || String(valor).trim() === '' ? null : String(valor).trim());

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
app.use('/reportes', express.static(DIR_REPORTES));

// ---------- ABM de anunciantes ----------
app.get('/api/anunciantes', async (req, res) => {
  try {
    const pool = await poolAbmListo;
    const r = await pool.request().execute('publicidad.consultar_anunciante');
    res.json(r.recordset);
  } catch (err) { responderError(res, err); }
});

app.post('/api/anunciantes', async (req, res) => {
  try {
    const pool = await poolAbmListo;
    const r = await pool.request()
      .input('nombre', sql.VarChar(100), texto(req.body.nombre))
      .input('razon_social', sql.VarChar(150), texto(req.body.razon_social))
      .input('contacto', sql.VarChar(100), texto(req.body.contacto))
      .output('anunciante_id', sql.Int)
      .execute('publicidad.anunciante_insertar');
    res.status(201).json({ anunciante_id: r.output.anunciante_id });
  } catch (err) { responderError(res, err); }
});

app.put('/api/anunciantes/:id', async (req, res) => {
  try {
    const pool = await poolAbmListo;
    await pool.request()
      .input('anunciante_id', sql.Int, Number(req.params.id))
      .input('nombre', sql.VarChar(100), texto(req.body.nombre))
      .input('razon_social', sql.VarChar(150), texto(req.body.razon_social))
      .input('contacto', sql.VarChar(100), texto(req.body.contacto))
      .execute('publicidad.anunciante_modificar');
    res.json({ ok: true });
  } catch (err) { responderError(res, err); }
});

app.delete('/api/anunciantes/:id', async (req, res) => {
  try {
    const pool = await poolAbmListo;
    await pool.request()
      .input('anunciante_id', sql.Int, Number(req.params.id))
      .execute('publicidad.anunciante_eliminar');
    res.json({ ok: true });
  } catch (err) { responderError(res, err); }
});

// ---------- Importación de archivos (Entrega 6) ----------
// Cada conjunto de datos tiene su SP de importación y un formato de archivo (JSON, CSV o XML). Se ejecutan con el administrador.
const IMPORTACIONES = {
  sedes:                  { sp: 'torneo.importar_sedes',                               extension: '.json', titulo: 'Sedes' },
  selecciones:            { sp: 'torneo.importar_selecciones',                         extension: '.json', titulo: 'Selecciones' },
  planteles:              { sp: 'plantel.importar_planteles',                          extension: '.json', titulo: 'Planteles (convocados)' },
  fixture:                { sp: 'torneo.importar_fixture',                             extension: '.json', titulo: 'Fixture (partidos y resultados)' },
  estadisticas_equipos:   { sp: 'torneo.importar_estadisticas_equipos_kaggle_2026',    extension: '.csv',  titulo: 'Estadísticas de equipos' },
  estadisticas_jugadores: { sp: 'plantel.importar_estadisticas_jugadores_kaggle_2026', extension: '.csv',  titulo: 'Estadísticas de jugadores' },
  tarifas:                { sp: 'publicidad.importar_tarifas',                         extension: '.xml',  titulo: 'Tarifas publicitarias' }
};

app.get('/api/importaciones/tipos', (req, res) => {
  res.json(Object.entries(IMPORTACIONES).map(([id, t]) => ({ id, titulo: t.titulo, extension: t.extension, formato: t.extension.slice(1).toUpperCase() })));
});

// El navegador manda el archivo como cuerpo crudo; el tipo y el nombre viajan en la URL.
app.post('/api/importaciones/:tipo', express.raw({ type: '*/*', limit: '60mb' }), async (req, res) => {
  const tipo = IMPORTACIONES[req.params.tipo];
  if (!tipo) return res.status(404).json({ error: 'Tipo de importación desconocido.' });
  if (!Buffer.isBuffer(req.body) || req.body.length === 0) return res.status(400).json({ error: 'No se recibió ningún archivo.' });

  const original = path.basename(String(req.query.nombre || 'archivo' + tipo.extension));
  if (path.extname(original).toLowerCase() !== tipo.extension) {
    return res.status(400).json({ error: 'Los datos de "' + tipo.titulo + '" se importan desde un archivo ' + tipo.extension.slice(1).toUpperCase() + ' (' + tipo.extension + ').' });
  }
  // Nombre único y sin caracteres raros: el SP recibe la ruta completa.
  const nombre = Date.now() + '_' + original.replace(/[^A-Za-z0-9._-]/g, '_');
  const rutaLocal = path.join(DIR_IMPORTACION, nombre);
  const separador = /^[A-Za-z]:|\\/.test(DIR_IMPORTACION_SQL) ? '\\' : '/';
  const rutaSql = DIR_IMPORTACION_SQL.replace(/[\\/]+$/, '') + separador + nombre;

  try {
    fs.writeFileSync(rutaLocal, req.body);
    const pool = await poolAdmin();
    const request = pool.request();
    const mensajes = [];
    request.on('info', info => mensajes.push(info.message));
    request.input('ruta_archivo', sql.VarChar(500), rutaSql);
    const r = await request.execute(tipo.sp);
    // El SP devuelve el resumen del lote (leídos, insertados, rechazados...) como último resultado.
    const resumen = (r.recordsets || []).find(rs => rs.length && 'lote_id' in rs[0]);
    res.json({ procedimiento: tipo.sp, archivo: original, resumen: resumen ? resumen[0] : null, mensajes });
  } catch (err) {
    responderError(res, err);
  } finally {
    fs.rm(rutaLocal, { force: true }, () => {});
  }
});

// ---------- Reportes XML (Entrega 7) ----------
const REPORTES = {
  goleadores: { sp: 'evento.reporte_goleadores', titulo: 'Goleadores del torneo' },
  plantillas: { sp: 'plantel.reporte_plantillas', titulo: 'Plantillas de las selecciones' }
};

app.get('/api/reportes/tipos', (req, res) => {
  res.json(Object.entries(REPORTES).map(([id, t]) => ({ id, titulo: t.titulo })));
});

// Ejecuta el reporte, guarda el XML en un archivo (carpeta reportes/) y lo devuelve.
app.post('/api/reportes/:tipo', async (req, res) => {
  const reporte = REPORTES[req.params.tipo];
  if (!reporte) return res.status(404).json({ error: 'Reporte desconocido.' });
  try {
    const pool = await poolAdmin();
    const r = await pool.request().execute(reporte.sp);
    const columna = (r.recordsets || []).map(rs => rs[0]).find(fila => fila && Object.keys(fila).length === 1);
    const xml = columna ? String(Object.values(columna)[0]) : null;
    if (!xml) return res.status(500).json({ error: 'El reporte no devolvió XML.' });
    const marca = new Date().toISOString().replace(/[-:]/g, '').replace('T', '_').slice(0, 15);
    const nombre = req.params.tipo + '_' + marca + '.xml';
    fs.writeFileSync(path.join(DIR_REPORTES, nombre), '<?xml version="1.0" encoding="UTF-8"?>\n' + xml, 'utf8');
    res.json({ reporte: reporte.sp, archivo: nombre, url: '/reportes/' + nombre, xml });
  } catch (err) { responderError(res, err); }
});

const puerto = Number(dato('PORT', 3000));
poolAbmListo
  .then(() => app.listen(puerto, () => console.log(`Aplicación en http://localhost:${puerto} (ABM: ${USUARIO_ABM}; importación y reportes: ${USUARIO_ADMIN})`)))
  .catch(err => { console.error('No se pudo conectar a SQL Server:', err.message); process.exit(1); });
