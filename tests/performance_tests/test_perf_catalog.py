# -------------------------------------------------------------------------------------------------
#  Copyright (C) 2015-2022 Nautech Systems Pty Ltd. All rights reserved.
#  https://nautechsystems.io
#
#  Licensed under the GNU Lesser General Public License Version 3.0 (the "License");
#  You may not use this file except in compliance with the License.
#  You may obtain a copy of the License at https://www.gnu.org/licenses/lgpl-3.0.en.html
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# -------------------------------------------------------------------------------------------------
from nautilus_trader.persistence.catalog import ParquetDataCatalog
from tests.test_kit.mocks.data import data_catalog_setup
from tests.test_kit.performance import PerformanceHarness
from tests.unit_tests.persistence.test_catalog import TestPersistenceCatalog


class TestBacktestEnginePerformance(PerformanceHarness):
    @staticmethod
    def test_load_quote_ticks_python(benchmark):
        def setup():
            # Arrange
            cls = TestPersistenceCatalog()
            data_catalog_setup(protocol="file")
            cls.catalog = ParquetDataCatalog.from_env()
            # cls.fs: fsspec.AbstractFileSystem = cls.catalog.fs

            # data_catalog_setup(protocol="file")
            # catalog = ParquetDataCatalog.from_env()
            # _load_data_into_catalog()
            cls._load_quote_ticks_into_catalog()

            # Act
            return (cls.catalog,), {}

        def run(catalog):
            catalog.quote_ticks(as_nautilus=True)

        benchmark.pedantic(run, setup=setup, rounds=10, iterations=1, warmup_rounds=5)

    @staticmethod
    def test_load_quote_ticks_rust(benchmark):
        def setup():
            # Arrange
            cls = TestPersistenceCatalog()
            data_catalog_setup(protocol="file")
            cls.catalog = ParquetDataCatalog.from_env()
            # cls.fs: fsspec.AbstractFileSystem = cls.catalog.fs

            # data_catalog_setup(protocol="file")
            # catalog = ParquetDataCatalog.from_env()
            # _load_data_into_catalog()
            cls._load_quote_ticks_into_catalog(use_rust=True)

            # Act
            return (cls.catalog,), {}

        def run(catalog):
            catalog.quote_ticks(as_nautilus=True, use_rust=True)

        benchmark.pedantic(run, setup=setup, rounds=10, iterations=1, warmup_rounds=5)
