const dropzone = document.getElementById("dropzone");
const fileInput = document.getElementById("fileInput");
const uploadBtn  = document.getElementById("uploadBtn");
const resultEl   = document.getElementById("result");

const pasteForm = document.getElementById("pasteForm");
const pasteContent = document.getElementById("pasteContent");
const pasteLang = document.getElementById("pasteLang");

let pendingFiles = [];

// ---------- UI helpers ----------
function setResult(obj) {
  resultEl.textContent =
    typeof obj === "string" ? obj : JSON.stringify(obj, null, 2);
}

function setDragover(isOver) {
  dropzone.classList.toggle("dragover", isOver);
}

// ---------- Network helpers ----------
async function postForm(url, form) {
  const res = await fetch(url, { method: "POST", body: form });

  // jscpd-friendly: one shared fetch+json+error path
  let data;
  try {
    data = await res.json();
  } catch {
    data = { ok: false, error: "Invalid JSON response" };
  }

  if (!res.ok) {
    setResult({ ok: false, status: res.status, data });
    return null;
  }

  return data;
}

function renderSavedLinks(data) {
  if (data?.saved?.length) {
    const lines = data.saved.map((s) => `${s.original_name} -> ${s.view_url}`);
    setResult(lines.join("\n"));
    return true;
  }
  return false;
}

// ---------- File queue helpers ----------
function addFiles(fileList) {
  const files = Array.from(fileList || []);
  if (!files.length) return;

  pendingFiles.push(...files);
  setResult(
    `Queued ${pendingFiles.length} file(s). Click "Upload selected" or drop/paste more.`
  );
}

async function uploadFiles(files) {
  const list = Array.from(files || []);
  if (!list.length) return setResult("No files queued.");

  const form = new FormData();
  for (const f of list) form.append("files", f);

  setResult("Uploading...");
  const data = await postForm("/upload", form);
  if (!data) return;

  if (!renderSavedLinks(data)) setResult(data);

  pendingFiles = [];
  if (fileInput) fileInput.value = "";
}

// ---------- Clipboard helpers ----------
function filesFromClipboardItems(items) {
  const files = [];
  for (const item of items) {
    if (item.kind === "file") {
      const f = item.getAsFile();
      if (f) files.push(f);
    }
  }
  return files;
}

function textFromClipboardItems(items) {
  const textItems = [];
  for (const item of items) {
    if (item.kind === "string") {
      textItems.push(
        new Promise((resolve) => item.getAsString((str) => resolve(str || "")))
      );
    }
  }
  return Promise.all(textItems).then((parts) => parts.join(""));
}

async function handlePaste(e) {
  const items = e.clipboardData?.items;
  if (!items) return;

  const files = filesFromClipboardItems(items);

  // If files exist, treat it as file paste
  if (files.length) {
    addFiles(files);
    return;
  }

  // Otherwise, try text paste
  const text = await textFromClipboardItems(items);
  if (text.trim() && pasteContent) {
    pasteContent.value = text;
    setResult("Pasted text into the textarea. Submit to create a link.");
  }
}

// ---------- Event wiring ----------

// File picker + button
if (fileInput) fileInput.addEventListener("change", (e) => addFiles(e.target.files));
if (uploadBtn) uploadBtn.addEventListener("click", () => uploadFiles(pendingFiles));

// Drag & drop
if (dropzone) {
  dropzone.addEventListener("dragover", (e) => {
    e.preventDefault();
    setDragover(true);
  });
  dropzone.addEventListener("dragleave", () => setDragover(false));
  dropzone.addEventListener("drop", (e) => {
    e.preventDefault();
    setDragover(false);
    if (e.dataTransfer?.files?.length) addFiles(e.dataTransfer.files);
  });

  dropzone.addEventListener("paste", (e) => {
    // paste event doesn’t need preventDefault unless you want to suppress default behavior
    handlePaste(e);
  });
}

// Paste form submit
if (pasteForm) {
  pasteForm.addEventListener("submit", async (e) => {
    e.preventDefault();

    const content = (pasteContent?.value || "").trim();
    if (!content) return setResult("Paste is empty.");

    const form = new FormData();
    form.append("content", content);
    form.append("language", pasteLang?.value || "plaintext");

    setResult("Creating paste link...");
    const data = await postForm("/paste", form);
    if (!data) return;

    setResult(`Paste created:\n${data.view_url}`);
    if (pasteContent) pasteContent.value = "";
  });
}

