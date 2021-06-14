﻿using AcademicSavingService.DataAccess;

namespace AcademicSavingService.Containers
{
	public class WithdrawSlipContainer : TransactionSlipContainer
	{
		private WithdrawSlipContainer()
        {
			_slipDA = new WithdrawSlipDA();
        }

		private static readonly WithdrawSlipContainer _instance = new();
		public static WithdrawSlipContainer Instance => _instance;
	}
}
