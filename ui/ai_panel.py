"""
Whisper Fedora UI - AI Processing Panel
Controls for AI-powered text processing and article generation
"""

from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QPushButton, 
    QLabel, QComboBox, QProgressBar, QFrame
)
from PyQt6.QtCore import Qt, pyqtSignal, QTimer
from PyQt6.QtGui import QFont

from text_processor import TextProcessor
from article_generator import ArticleGenerator, ArticleFormat, ARTICLE_FORMAT_INFO


class StatusIndicator(QWidget):
    """Small status indicator with colored dot and label."""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._setup_ui()
        self._connected = False
        self._model_name = None
    
    def _setup_ui(self):
        layout = QHBoxLayout(self)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(6)
        
        self.dot = QLabel("●")
        self.dot.setStyleSheet("color: #ef4444; font-size: 10px;")  # Red = disconnected
        layout.addWidget(self.dot)
        
        self.label = QLabel("LM Studio")
        self.label.setStyleSheet("color: #888; font-size: 11px;")
        layout.addWidget(self.label)
        
        layout.addStretch()
    
    def set_connected(self, connected: bool, model_name: str = None):
        """Update connection status."""
        self._connected = connected
        self._model_name = model_name
        
        if connected:
            self.dot.setStyleSheet("color: #22c55e; font-size: 10px;")  # Green
            if model_name:
                # Truncate long model names
                display_name = model_name[:25] + "..." if len(model_name) > 25 else model_name
                self.label.setText(f"LM Studio: {display_name}")
                self.label.setStyleSheet("color: #22c55e; font-size: 11px;")
            else:
                self.label.setText("LM Studio: Connected")
                self.label.setStyleSheet("color: #22c55e; font-size: 11px;")
        else:
            self.dot.setStyleSheet("color: #ef4444; font-size: 10px;")  # Red
            self.label.setText("LM Studio: Offline")
            self.label.setStyleSheet("color: #888; font-size: 11px;")
    
    @property
    def is_connected(self) -> bool:
        return self._connected


class AIProcessingPanel(QWidget):
    """Panel with AI processing controls."""
    
    # Signals
    clean_requested = pyqtSignal()
    generate_requested = pyqtSignal(str)  # Article format key
    generate_all_requested = pyqtSignal()
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._processor = TextProcessor()
        self._generator = ArticleGenerator()
        self._processing = False
        self._setup_ui()
        self._start_connection_check()
    
    def _setup_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(0, 8, 0, 0)
        layout.setSpacing(8)
        
        # Divider
        divider = QFrame()
        divider.setFrameShape(QFrame.Shape.HLine)
        divider.setStyleSheet("background-color: #3a3a3a;")
        divider.setFixedHeight(1)
        layout.addWidget(divider)
        
        # Section header
        header = QLabel("🤖 AI Processing")
        header.setStyleSheet("color: #888; font-size: 12px; font-weight: bold; margin-top: 4px;")
        layout.addWidget(header)
        
        # Connection status
        self.status_indicator = StatusIndicator()
        layout.addWidget(self.status_indicator)
        
        # Progress bar (hidden by default)
        self.progress_bar = QProgressBar()
        self.progress_bar.setVisible(False)
        self.progress_bar.setStyleSheet("""
            QProgressBar { 
                border: none; 
                border-radius: 3px; 
                background-color: #2a2a2a; 
                height: 4px; 
            }
            QProgressBar::chunk { 
                background-color: #6366f1; 
                border-radius: 3px; 
            }
        """)
        self.progress_bar.setTextVisible(False)
        self.progress_bar.setFixedHeight(4)
        layout.addWidget(self.progress_bar)
        
        # Progress label
        self.progress_label = QLabel("")
        self.progress_label.setStyleSheet("color: #888; font-size: 10px;")
        self.progress_label.setVisible(False)
        layout.addWidget(self.progress_label)
        
        # Button style
        button_style = """
            QPushButton {
                background-color: #2a2a2a;
                border: 1px solid #3a3a3a;
                border-radius: 6px;
                padding: 8px 12px;
                color: #e0e0e0;
                font-size: 12px;
                text-align: left;
            }
            QPushButton:hover {
                background-color: #3a3a3a;
                border-color: #5a5a5a;
            }
            QPushButton:pressed {
                background-color: #4a4a4a;
            }
            QPushButton:disabled {
                background-color: #1a1a1a;
                color: #555;
                border-color: #2a2a2a;
            }
        """
        
        # Clean Text button
        self.clean_btn = QPushButton("✨ Clean Text")
        self.clean_btn.setStyleSheet(button_style)
        self.clean_btn.setToolTip("Remove filler words, fix punctuation, create paragraphs")
        self.clean_btn.clicked.connect(self._on_clean_clicked)
        self.clean_btn.setEnabled(False)
        layout.addWidget(self.clean_btn)
        
        # Generate Articles section
        articles_layout = QHBoxLayout()
        articles_layout.setSpacing(4)
        
        self.generate_btn = QPushButton("📝 Generate")
        self.generate_btn.setStyleSheet(button_style)
        self.generate_btn.setToolTip("Generate article in selected format")
        self.generate_btn.clicked.connect(self._on_generate_clicked)
        self.generate_btn.setEnabled(False)
        articles_layout.addWidget(self.generate_btn, stretch=1)
        
        # Format selector
        self.format_combo = QComboBox()
        self.format_combo.setFixedWidth(90)
        self.format_combo.setStyleSheet("""
            QComboBox {
                padding: 6px 8px;
                padding-right: 20px;
                border: 1px solid #3a3a3a;
                border-radius: 6px;
                background-color: #2a2a2a;
                color: #e0e0e0;
                font-size: 11px;
            }
            QComboBox:hover {
                border-color: #5a5a5a;
            }
            QComboBox::drop-down {
                subcontrol-origin: padding;
                subcontrol-position: center right;
                width: 16px;
                border: none;
            }
            QComboBox::down-arrow {
                width: 0;
                height: 0;
                border-left: 3px solid transparent;
                border-right: 3px solid transparent;
                border-top: 3px solid #888;
            }
            QComboBox QAbstractItemView {
                background-color: #2a2a2a;
                border: 1px solid #3a3a3a;
                selection-background-color: #6366f1;
                color: #e0e0e0;
            }
        """)
        
        # Add format options
        for fmt in ArticleFormat:
            info = ARTICLE_FORMAT_INFO[fmt]
            # Use emoji in text, not as icon (QIcon requires actual icon, not string)
            display_text = f"{info['icon']} {info['name'].split()[1]}"
            self.format_combo.addItem(display_text, fmt.value)
        
        articles_layout.addWidget(self.format_combo)
        layout.addLayout(articles_layout)
        
        # Generate All button
        self.generate_all_btn = QPushButton("📚 Generate All Formats")
        self.generate_all_btn.setStyleSheet(button_style)
        self.generate_all_btn.setToolTip("Generate articles in all 5 formats")
        self.generate_all_btn.clicked.connect(self._on_generate_all_clicked)
        self.generate_all_btn.setEnabled(False)
        layout.addWidget(self.generate_all_btn)
        
        layout.addStretch()
    
    def _start_connection_check(self):
        """Start periodic connection check."""
        self._check_connection()
        
        # Check connection every 10 seconds
        self.check_timer = QTimer(self)
        self.check_timer.timeout.connect(self._check_connection)
        self.check_timer.start(10000)
    
    def _check_connection(self):
        """Check LM Studio connection status."""
        if self._processing:
            return  # Don't check while processing
        
        connected = self._processor.is_available()
        model_name = self._processor.get_model_name() if connected else None
        self.status_indicator.set_connected(connected, model_name)
    
    def set_has_transcription(self, has_transcription: bool):
        """Enable/disable buttons based on transcription availability."""
        connected = self.status_indicator.is_connected
        enabled = has_transcription and connected and not self._processing
        
        self.clean_btn.setEnabled(enabled)
        self.generate_btn.setEnabled(enabled)
        self.generate_all_btn.setEnabled(enabled)
    
    def set_processing(self, processing: bool):
        """Set processing state."""
        self._processing = processing
        self.progress_bar.setVisible(processing)
        self.progress_label.setVisible(processing)
        
        if not processing:
            self.progress_bar.setValue(0)
            self.progress_label.setText("")
        
        # Update button states
        self.clean_btn.setEnabled(not processing and self.status_indicator.is_connected)
        self.generate_btn.setEnabled(not processing and self.status_indicator.is_connected)
        self.generate_all_btn.setEnabled(not processing and self.status_indicator.is_connected)
    
    def update_progress(self, percentage: int, message: str):
        """Update progress display."""
        self.progress_bar.setValue(percentage)
        self.progress_label.setText(message)
    
    def _on_clean_clicked(self):
        """Handle Clean Text button click."""
        self.clean_requested.emit()
    
    def _on_generate_clicked(self):
        """Handle Generate button click."""
        format_key = self.format_combo.currentData()
        self.generate_requested.emit(format_key)
    
    def _on_generate_all_clicked(self):
        """Handle Generate All button click."""
        self.generate_all_requested.emit()
    
    def get_selected_format(self) -> ArticleFormat:
        """Get the currently selected article format."""
        format_key = self.format_combo.currentData()
        return ArticleFormat(format_key)
