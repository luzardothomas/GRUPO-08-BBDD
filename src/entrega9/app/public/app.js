// Cliente del ABM de anunciantes: sólo muestra datos y manda lo que el usuario escribe.
// Las validaciones las hacen los procedimientos almacenados; acá se muestra su mensaje tal cual.
const $ = id => document.getElementById(id);

// Muestra un mensaje en la caja indicada (tipo: 'ok' o 'error'; sin texto, la oculta).
function mensajeEn(id, texto, tipo) {
  const caja = $(id);
  caja.textContent = texto || '';
  caja.className = tipo || '';
  caja.hidden = !texto;
}
const form = $('form');
const campos = ['nombre', 'razon_social', 'contacto'];

function mostrar(texto, tipo) {
  const caja = $('mensaje');
  caja.textContent = texto;
  caja.className = tipo;
  caja.hidden = !texto;
}

async function pedir(url, opciones) {
  const r = await fetch(url, { headers: { 'Content-Type': 'application/json' }, ...opciones });
  const datos = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(datos.error || 'Error ' + r.status);
  return datos;
}

function limpiarFormulario() {
  form.reset();
  $('anunciante_id').value = '';
  $('titulo-form').textContent = 'Nuevo anunciante';
  $('cancelar').hidden = true;
}

async function cargar() {
  const filas = $('filas');
  filas.replaceChildren();
  try {
    const anunciantes = await pedir('/api/anunciantes');
    $('cantidad').textContent = '(' + anunciantes.length + ')';
    for (const a of anunciantes) {
      const tr = document.createElement('tr');
      for (const valor of [a.anunciante_id, a.nombre, a.razon_social, a.contacto]) {
        const td = document.createElement('td');
        td.textContent = valor === null || valor === undefined ? '' : valor;
        tr.appendChild(td);
      }
      const acciones = document.createElement('td');
      acciones.className = 'botones';
      const editar = document.createElement('button');
      editar.className = 'secundario';
      editar.textContent = 'Editar';
      editar.onclick = () => editarAnunciante(a);
      const borrar = document.createElement('button');
      borrar.className = 'peligro';
      borrar.textContent = 'Eliminar';
      borrar.onclick = () => eliminarAnunciante(a);
      acciones.append(editar, ' ', borrar);
      tr.appendChild(acciones);
      filas.appendChild(tr);
    }
  } catch (err) {
    mostrar(err.message, 'error');
  }
}

function editarAnunciante(a) {
  $('anunciante_id').value = a.anunciante_id;
  for (const c of campos) $(c).value = a[c] || '';
  $('titulo-form').textContent = 'Modificar anunciante ' + a.anunciante_id;
  $('cancelar').hidden = false;
  $('nombre').focus();
  mostrar('', '');
}

async function eliminarAnunciante(a) {
  if (!confirm('¿Eliminar el anunciante "' + a.nombre + '"?')) return;
  try {
    await pedir('/api/anunciantes/' + a.anunciante_id, { method: 'DELETE' });
    mostrar('Anunciante eliminado.', 'ok');
    if ($('anunciante_id').value === String(a.anunciante_id)) limpiarFormulario();
    cargar();
  } catch (err) {
    mostrar(err.message, 'error');
  }
}

form.addEventListener('submit', async evento => {
  evento.preventDefault();
  const id = $('anunciante_id').value;
  const cuerpo = Object.fromEntries(campos.map(c => [c, $(c).value]));
  try {
    if (id) {
      await pedir('/api/anunciantes/' + id, { method: 'PUT', body: JSON.stringify(cuerpo) });
      mostrar('Anunciante modificado.', 'ok');
    } else {
      const r = await pedir('/api/anunciantes', { method: 'POST', body: JSON.stringify(cuerpo) });
      mostrar('Anunciante creado con id ' + r.anunciante_id + '.', 'ok');
    }
    limpiarFormulario();
    cargar();
  } catch (err) {
    mostrar(err.message, 'error');
  }
});

$('cancelar').addEventListener('click', () => { limpiarFormulario(); mostrar('', ''); });
cargar();


// ---------- Pestañas ----------
function mostrarVista(nombre) {
  $('vista-anunciantes').hidden = nombre !== 'anunciantes';
  $('vista-importacion').hidden = nombre !== 'importacion';
  $('tab-anunciantes').setAttribute('aria-selected', String(nombre === 'anunciantes'));
  $('tab-importacion').setAttribute('aria-selected', String(nombre === 'importacion'));
}
$('tab-anunciantes').addEventListener('click', () => mostrarVista('anunciantes'));
$('tab-importacion').addEventListener('click', () => { mostrarVista('importacion'); prepararImportacion(); });

// ---------- Importación (Entrega 6) ----------
let tiposImportacion = [];
let importacionLista = false;

async function prepararImportacion() {
  if (importacionLista) return;
  try {
    tiposImportacion = await pedir('/api/importaciones/tipos');
    const formatos = [...new Set(tiposImportacion.map(t => t.formato))];
    for (const f of formatos) {
      const opcion = document.createElement('option');
      opcion.value = f;
      opcion.textContent = f;
      $('imp-formato').appendChild(opcion);
    }
    actualizarDatos();
    const reportes = await pedir('/api/reportes/tipos');
    for (const r of reportes) {
      const boton = document.createElement('button');
      boton.type = 'button';
      boton.textContent = r.titulo;
      boton.onclick = () => generarReporte(r.id);
      $('rep-botones').appendChild(boton);
    }
    importacionLista = true;
  } catch (err) {
    mensajeEn('imp-mensaje', err.message, 'error');
  }
}

// Al elegir el formato se listan sólo los datos que se importan en ese formato.
function actualizarDatos() {
  const select = $('imp-tipo');
  select.replaceChildren();
  for (const t of tiposImportacion.filter(t => t.formato === $('imp-formato').value)) {
    const opcion = document.createElement('option');
    opcion.value = t.id;
    opcion.textContent = t.titulo;
    select.appendChild(opcion);
  }
  actualizarExtension();
}

function actualizarExtension() {
  const extension = (tiposImportacion.find(t => t.id === $('imp-tipo').value) || {}).extension || '';
  $('imp-extension').textContent = extension ? '(' + extension + ')' : '';
  $('imp-archivo').accept = extension;
  $('imp-archivo').value = '';
}
$('imp-formato').addEventListener('change', actualizarDatos);
$('imp-tipo').addEventListener('change', actualizarExtension);

$('form-importacion').addEventListener('submit', async evento => {
  evento.preventDefault();
  const archivo = $('imp-archivo').files[0];
  if (!archivo) return mensajeEn('imp-mensaje', 'Elegí un archivo para importar.', 'error');
  $('imp-resultado').hidden = true;
  mensajeEn('imp-mensaje', 'Importando...', '');
  try {
    const r = await fetch('/api/importaciones/' + $('imp-tipo').value + '?nombre=' + encodeURIComponent(archivo.name),
      { method: 'POST', headers: { 'Content-Type': 'application/octet-stream' }, body: archivo });
    const datos = await r.json().catch(() => ({}));
    if (!r.ok) throw new Error(datos.error || 'Error ' + r.status);
    mostrarResumen(datos);
  } catch (err) {
    mensajeEn('imp-mensaje', err.message, 'error');
  }
});

function mostrarResumen(datos) {
  const fila = $('imp-fila');
  fila.replaceChildren();
  const r = datos.resumen;
  if (!r) {
    mensajeEn('imp-mensaje', 'Importación ejecutada (' + datos.procedimiento + '); el procedimiento no devolvió resumen.', 'ok');
    return;
  }
  const tr = document.createElement('tr');
  for (const clave of ['lote_id', 'proceso', 'leidos', 'insertados', 'actualizados', 'sin_cambios', 'rechazados', 'estado']) {
    const td = document.createElement('td');
    td.textContent = r[clave];
    if (clave === 'estado') td.className = 'estado-' + r[clave];
    tr.appendChild(td);
  }
  fila.appendChild(tr);
  const textoEstado = { completo: 'Importación completa.', parcial: 'Importación parcial: se importaron las filas válidas y se rechazaron ' + r.rechazados + '.', rechazado: 'Importación rechazada: ninguna fila se pudo importar.' }[r.estado];
  mensajeEn('imp-mensaje', textoEstado + (datos.mensajes.length ? '\n' + datos.mensajes.join('\n') : ''), r.estado === 'rechazado' ? 'error' : 'ok');
  $('imp-resultado').hidden = false;
}

// ---------- Reportes XML (Entrega 7) ----------
async function generarReporte(id) {
  $('rep-resultado').hidden = true;
  mensajeEn('rep-mensaje', 'Generando el reporte...', '');
  try {
    const datos = await pedir('/api/reportes/' + id, { method: 'POST' });
    $('rep-enlace').textContent = datos.archivo;
    $('rep-enlace').href = datos.url;
    $('rep-xml').textContent = datos.xml;
    $('rep-resultado').hidden = false;
    mensajeEn('rep-mensaje', 'Reporte generado con ' + datos.reporte + '.', 'ok');
  } catch (err) {
    mensajeEn('rep-mensaje', err.message, 'error');
  }
}
