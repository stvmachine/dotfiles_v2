#!/usr/bin/env python3
"""
Setup script for GSD (Get Shit Done) kimi plugin
"""

from setuptools import setup, find_packages
from pathlib import Path

# Read README
readme_file = Path(__file__).parent / "SKILL.md"
readme = readme_file.read_text() if readme_file.exists() else ""

setup(
    name="gsd-kimi",
    version="1.0.0",
    description="Get Shit Done (GSD) - Spec-driven development for Kimi CLI",
    long_description=readme,
    long_description_content_type="text/markdown",
    author="GSD Team",
    packages=find_packages(),
    py_modules=["gsd"],
    install_requires=[],
    python_requires=">=3.10",
    entry_points={
        "console_scripts": [
            "gsd=gsd:main",
            "gsd-kimi=gsd:main",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Python :: 3.13",
        "Topic :: Software Development :: Libraries :: Python Modules",
    ],
    include_package_data=True,
    package_data={
        "": ["*.md", "*.xml", "*.json", "templates/*", "agents/*"],
    },
)
