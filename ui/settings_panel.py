"""
Whisper Fedora UI - Settings Panel
Model, language, compute device, and output format settings
"""

from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel, QComboBox,
    QCheckBox, QGroupBox, QFormLayout
)
from PyQt6.QtCore import pyqtSignal

from utils import WHISPER_MODELS, WHISPER_LANGUAGES, detect_gpu


class SettingsPanel(QWidget):
    """Settings panel for transcription options."""
    
    # Signal emitted when settings change
    settings_changed = pyqtSignal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._setup_ui()
    
    def _setup_ui(self):
        """Set up the UI components."""
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(16)
        
        # Model selection group
        model_group = QGroupBox("Model")
        model_group.setStyleSheet("""
            QGroupBox {
                font-weight: bold;
                border: 1px solid #3a3a3a;
                border-radius: 8px;
                margin-top: 12px;
                padding-top: 8px;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                left: 12px;
                padding: 0 8px;
            }
        """)
        model_layout = QFormLayout(model_group)
        model_layout.setContentsMargins(16, 20, 16, 16)
        
        self.model_combo = QComboBox()
        self.model_combo.setStyleSheet("""
            QComboBox {
                padding: 8px 12px;
                border-radius: 6px;
                min-width: 200px;
            }
        """)
        for model_id, model_desc in WHISPER_MODELS:
            self.model_combo.addItem(model_desc, model_id)
        self.model_combo.setCurrentIndex(1)  # Default to 'base'
        self.model_combo.currentIndexChanged.connect(self._on_settings_changed)
        model_layout.addRow("Whisper Model:", self.model_combo)
        
        layout.addWidget(model_group)
        
        # Language group
        lang_group = QGroupBox("Language")
        lang_group.setStyleSheet(model_group.styleSheet())
        lang_layout = QFormLayout(lang_group)
        lang_layout.setContentsMargins(16, 20, 16, 16)
        
        self.language_combo = QComboBox()
        self.language_combo.setStyleSheet(self.model_combo.styleSheet())
        for lang_code, lang_name in WHISPER_LANGUAGES:
            self.language_combo.addItem(lang_name, lang_code)
        self.language_combo.currentIndexChanged.connect(self._on_settings_changed)
        lang_layout.addRow("Source Language:", self.language_combo)
        
        self.translate_checkbox = QCheckBox("Translate to English")
        self.translate_checkbox.setStyleSheet("padding: 4px 0;")
        self.translate_checkbox.stateChanged.connect(self._on_settings_changed)
        lang_layout.addRow("", self.translate_checkbox)
        
        layout.addWidget(lang_group)
        
        # Compute device group
        compute_group = QGroupBox("Compute Device")
        compute_group.setStyleSheet(model_group.styleSheet())
        compute_layout = QFormLayout(compute_group)
        compute_layout.setContentsMargins(16, 20, 16, 16)
        
        # Detect GPU
        gpu_type, gpu_name = detect_gpu()
        
        self.device_combo = QComboBox()
        self.device_combo.setStyleSheet(self.model_combo.styleSheet())
        
        # Add available compute options
        if gpu_type == 'cuda':
            self.device_combo.addItem(f"🚀 {gpu_name}", 'cuda')
        elif gpu_type == 'rocm':
            self.device_combo.addItem(f"🚀 {gpu_name}", 'rocm')
        self.device_combo.addItem("💻 CPU", 'cpu')
        
        self.device_combo.currentIndexChanged.connect(self._on_settings_changed)
        compute_layout.addRow("Device:", self.device_combo)
        
        # Device info label
        self.device_info = QLabel()
        self.device_info.setStyleSheet("color: #888; font-size: 11px;")
        self._update_device_info()
        self.device_combo.currentIndexChanged.connect(self._update_device_info)
        compute_layout.addRow("", self.device_info)
        
        layout.addWidget(compute_group)
        
        # Output format group
        output_group = QGroupBox("Output Format")
        output_group.setStyleSheet(model_group.styleSheet())
        output_layout = QFormLayout(output_group)
        output_layout.setContentsMargins(16, 20, 16, 16)
        
        self.format_combo = QComboBox()
        self.format_combo.setStyleSheet(self.model_combo.styleSheet())
        self.format_combo.addItem("Plain Text (.txt)", 'txt')
        self.format_combo.addItem("Text with Timestamps (.txt)", 'txt_ts')
        self.format_combo.addItem("SRT Subtitles (.srt)", 'srt')
        self.format_combo.addItem("WebVTT Subtitles (.vtt)", 'vtt')
        self.format_combo.addItem("JSON (.json)", 'json')
        self.format_combo.currentIndexChanged.connect(self._on_settings_changed)
        output_layout.addRow("Export As:", self.format_combo)
        
        layout.addWidget(output_group)
        
        # Spacer
        layout.addStretch()
    
    def _on_settings_changed(self):
        """Handle settings change."""
        self.settings_changed.emit()
    
    def _update_device_info(self):
        """Update device info label."""
        device = self.device_combo.currentData()
        if device == 'cuda':
            self.device_info.setText("Using NVIDIA CUDA for GPU acceleration")
        elif device == 'rocm':
            self.device_info.setText("Using AMD ROCm for GPU acceleration")
        else:
            self.device_info.setText("Using CPU (slower but compatible)")
    
    def get_model(self) -> str:
        """Get selected model name."""
        return self.model_combo.currentData()
    
    def get_language(self) -> str:
        """Get selected language code."""
        return self.language_combo.currentData()
    
    def get_translate(self) -> bool:
        """Get translate to English setting."""
        return self.translate_checkbox.isChecked()
    
    def get_device(self) -> str:
        """Get selected compute device."""
        return self.device_combo.currentData()
    
    def get_export_format(self) -> str:
        """Get selected export format."""
        return self.format_combo.currentData()
