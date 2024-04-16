import { Controller } from "@hotwired/stimulus";

const FILE_CLASS_NAMES = ['opacity-0', 'translate-y-8'];

export default class extends Controller {
  static targets = [
    'fileInput',
    'uploadedContent',
    'fileTemplate',
    'fileUploadSection',
  ];

  connect() {
    this.upToDateFileList = new DataTransfer();
    this.acceptArray = this.fileInputTarget.accept?.split(',');
    this.acceptRegex = new RegExp(this.acceptArray.join('|'));
  }

  dropUpload(event) {
    event.preventDefault();
    this.uploadFiles(event);
    this.fileUploadSectionTarget.classList.remove('dragged-over');
  }

  selectUpload(event) {
    this.uploadFiles(event);
  }

  uploadFiles(event) {
    const files =
      event.type === 'drop'
        ? Array.from(event.dataTransfer.files)
        : Array.from(event.target.files);

    const validFiles = files.map((file) => this.fileValidation(file));
    const results = validFiles.filter(Boolean);

    this.appendFiles(results);
    this.fileInputTarget.files = this.upToDateFileList.files;
  }

  appendFiles(results) {
    results.map((file) => {
      this.upToDateFileList.items.add(file);
      this.appendFile(file);
      return true;
    });
  }

  fileValidation(file) {
    if (this.fileInputTarget.accept) {
      if (!this.acceptRegex.test(file.type)) {
        return false;
      }
    }

    return file;
  }

  appendFile(file) {
    const domId = Math.random().toString(36).slice(2);
    const newFileElement = this.fileTemplateTarget.content.cloneNode(true);

    const { name: fileName, type: fileType } = file;

    newFileElement.firstElementChild.id = domId;

    const fileNameHolder = newFileElement.querySelector(".filename");

    fileNameHolder.innerHTML = fileName;
    fileNameHolder.title = fileName;

    const isImage = (fileType.split('/')[0] || '') === 'image';
    const toUseIcon = isImage ? 'imageIcon' : 'documentIcon';
    newFileElement.querySelector(`.${toUseIcon}`).classList.remove('hidden');
    this.animateFile({ domId });
    this.uploadedContentTarget.appendChild(newFileElement);
  }

  removeFile(event) {
    const parent = event.currentTarget.parentElement;
    const targetIndex = Array.prototype.indexOf.call(
      this.uploadedContentTarget.children,
      parent
    );

    parent.remove();
    this.upToDateFileList.items.remove(targetIndex);
    this.fileInputTarget.files = this.upToDateFileList.files;
  }

  animateFile({ domId, showItem = true }) {
    if (showItem) {
      setTimeout(() => {
        document.getElementById(domId).classList.remove(...FILE_CLASS_NAMES);
      }, 200);
    } else {
      document.getElementById(domId).classList.add(...FILE_CLASS_NAMES);
    }
  }

  dragLeaveHandler(event) {
    event.preventDefault();
    this.fileUploadSectionTarget.classList.remove('dragged-over');
  }

  dragEnterHandler(event) {
    event.preventDefault();
    this.fileUploadSectionTarget.classList.add('dragged-over');
  }
}
