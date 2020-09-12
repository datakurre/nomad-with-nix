from setuptools import setup, find_packages

setup(
    name="app",
    py_modules=[
        "main",
    ],
    install_requires=[
        "databases",
        "fastapi",
        "uvicorn",
    ],
    entry_points={
        "console_scripts": ["uvicorn=uvicorn:main"],
    },
)
