from setuptools import setup, find_packages

setup(
    name="app",
    py_modules=[
        "main",
    ],
    install_requires=[
        "asyncpg",
        "databases",
        "fastapi",
        "psycopg2",
        "uvicorn",
    ],
    entry_points={
        "console_scripts": ["uvicorn=uvicorn:main"],
    },
)
