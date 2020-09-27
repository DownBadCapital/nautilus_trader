# -------------------------------------------------------------------------------------------------
#  Copyright (C) 2015-2020 Nautech Systems Pty Ltd. All rights reserved.
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

"""Define common basic value objects in the trading domain."""

from nautilus_trader.core.correctness cimport Condition
from nautilus_trader.core.decimal cimport Decimal64
from nautilus_trader.core.functions cimport precision_from_string
from nautilus_trader.model.c_enums.currency cimport Currency
from nautilus_trader.model.c_enums.currency cimport currency_to_string


cdef Quantity _ZERO_QUANTITY = Quantity()
cdef Quantity _ONE_QUANTITY = Quantity(value=1, precision=0)


cdef class Quantity(Decimal64):
    """
    Represents a quantity with a non-negative value.

    Attributes
    ----------
    precision : int
        The precision of the underlying decimal value.

    """

    def __init__(self, double value=0, int precision=0):
        """
        Initialize a new instance of the Quantity class.

        Parameters
        ----------
        value : double
            The value of the quantity.
        precision : int, optional.
            The decimal precision of the quantity.
            Only used if value is not a string.

        Raises
        ------
        ValueError
            If value is negative (< 0).
        ValueError
            If precision is negative (< 0).

        """
        Condition.not_negative(value, "value")
        super().__init__(value, precision)

    @staticmethod
    cdef Quantity from_string(str value):
        """
        Return a quantity from the given string.

        Precision will be inferred from the number of digits after the decimal place.

        Parameters
        ----------
        value : str
            The string value to parse.

        Returns
        -------
        Quantity

        """
        Condition.valid_string(value, "value")

        return Quantity(float(value), precision=precision_from_string(value))

    cpdef bint equals(self, Quantity other):
        """
        Return a value indicating whether this object is equal to (==) the given object.

        Parameters
        ----------
        other : object
            The other object to equate.

        Returns
        -------
        bool

        """
        return self.eq(other)

    @staticmethod
    cdef Quantity zero():
        """
        Return a quantity of zero.

        Returns
        -------
        Money

        """
        return _ZERO_QUANTITY

    @staticmethod
    cdef Quantity one():
        """
        Return a quantity with a value of 1, and precision of 0.

        Returns
        -------
        Quantity

        """
        return _ONE_QUANTITY

    cpdef Quantity add(self, Quantity other):
        """
        Return a new quantity by adding the given quantity to this quantity.

        Parameters
        ----------
        other : Quantity
            The other quantity to add.

        Returns
        -------
        Quantity

        """
        return Quantity(self._value + other._value, max(self.precision, other.precision))

    cpdef Quantity sub(self, Quantity other):
        """
        Return a new quantity by subtracting the quantity from this quantity.

        Parameters
        ----------
        other : Quantity
            The other quantity to subtract.

        Returns
        -------
        Quantity

        Raises
        ------
        ValueError
            If value of the other decimal is greater than this price.

        """
        return Quantity(self._value - other._value, max(self.precision, other.precision))

    cpdef str to_string_formatted(self):
        """
        Return the formatted string representation of this object.
        """
        if self.precision > 0:
            return f"{self._value:.{self.precision}f}"

        if self._value < 1000 or self._value % 1000 != 0:
            return f"{self._value:.{self.precision}f}"

        if self._value < 1000000:
            return f"{self._value / 1000:.{0}f}K"

        cdef str millions = f"{self._value / 1000000:.{3}f}".rstrip("0").rstrip(".")
        return f"{millions}M"


cdef class Price(Decimal64):
    """
    Represents the price of a financial market instrument.
    """

    def __init__(self, double value, int precision):
        """
        Initialize a new instance of the Price class.

        Parameters
        ----------
        value : double
            The value of the price (>= 0).
        precision : int
            The decimal precision of the price (>= 0).

        Raises
        ------
        ValueError
            If value is negative (< 0).
        ValueError
            If precision is negative (< 0).

        """
        Condition.not_negative(value, "value")
        super().__init__(value, precision)

    @staticmethod
    cdef Price from_string(str value):
        """
        Return a price from the given string.

        Precision will be inferred from the number of digits after the decimal place.

        Parameters
        ----------
        value : str
            The string value to parse.
        Returns
        -------
        Price
        """
        Condition.valid_string(value, "value")

        return Price(float(value), precision=precision_from_string(value))

    cpdef bint equals(self, Price other):
        """
        Return a value indicating whether this object is equal to (==) the given object.

        Parameters
        ----------
        other : object
            The other object to equate.

        Returns
        -------
        bool

        """
        return self.eq(other)

    cpdef Price add(self, Decimal64 other):
        """
        Return a new price by adding the given decimal to this price.

        Parameters
        ----------
        other : Decimal64
            The other decimal to add (precision must be <= this decimals precision).

        Returns
        -------
        Price

        Raises
        ------
        ValueError
            If precision of the other decimal is > this precision.

        """
        Condition.true(self.precision >= other.precision, "self.precision >= price.precision")

        return Price(self._value + other._value, self.precision)

    cpdef Price sub(self, Decimal64 other):
        """
        Return a new price by subtracting the decimal price from this price.

        Parameters
        ----------
        other : Decimal64
            The other decimal to subtract (precision must be <= this decimals precision).

        Returns
        -------
        Price

        Raises
        ------
        ValueError
            If precision of the other decimal is not <= this precision.
        ValueError
            If value of the other decimal is greater than this price.

        """
        Condition.true(self.precision >= other.precision, "self.precision >= price.precision")

        return Price(self._value - other._value, self.precision)


cdef class Money(Decimal64):
    """
    Represents the 'concept' of money including currency type.
    """

    def __init__(self, value, Currency currency, int precision=2):
        """
        Initialize a new instance of the Money class.

        Parameters
        ----------
        value : integer, string, tuple, float, or decimal.Decimal.
            The value of the money.
        currency : Currency
            The currency of the money.
        precision : int, optional
            The denomination precision for the currency.

        Raises
        ------
        ValueError
            If currency is UNDEFINED.
        ValueError
            If precision is negative (< 0).

        """
        Condition.not_equal(currency, Currency.UNDEFINED, "currency", "UNDEFINED")
        Condition.not_negative_int(precision, "precision")
        super().__init__(value, precision)

        self.currency = currency

    @staticmethod
    cdef Money from_string(str value, Currency currency):
        """
        Return money parsed from the given string value.
        Precision will be inferred from the number of digits after the decimal place.

        Parameters
        ----------
        value : str
            The string value to parse.
        currency : Currency
            The currency for the money.

        Returns
        -------
        Money

        """
        Condition.valid_string(value, "value")

        return Money(float(value), currency, precision=precision_from_string(value))

    cpdef bint equals(self, Money other):
        """
        Return a value indicating whether this object is equal to (==) the given object.

        Parameters
        ----------
        other : Money
            The other object.

        Returns
        -------
        bool

        Raises
        ------
        ValueError
            If other is not of type Money.

        """
        return self.eq(other) and self.currency == other.currency

    cpdef Money add(self, Money other):
        """
        Return new money by adding the given money to this money.

        Parameters
        ----------
        other : Money
            The other money to add.

        Returns
        -------
        Money

        Raises
        ------
        ValueError
            If other currency is not equal to this monies.

        """
        Condition.equal(self.currency, other.currency, "self.currency", "other.currency")

        return Money(self._value + other._value, self.currency)

    cpdef Money sub(self, Money other):
        """
        Return new money by subtracting the given money from this money.

        Parameters
        ----------
        other : Money
            The other money to subtract.

        Returns
        -------
        Money

        Raises
        ------
        ValueError
            If other currency is not equal to this money.

        """
        Condition.equal(self.currency, other.currency, "self.currency", "other.currency")

        return Money(self._value - other._value, self.currency)

    cpdef str to_string_formatted(self):
        """
        Return the formatted string representation of this object.

        Returns
        -------
        str

        """
        return f"{self.to_string(format_commas=True)} {currency_to_string(self.currency)}"

    def __repr__(self) -> str:
        """
        Return the string representation of this object which includes the objects
        location in memory.

        Returns
        -------
        str

        """
        return (f"<{self.__class__.__name__}({self.to_string()}, currency={currency_to_string(self.currency)}) "
                f"object at {id(self)}>")
