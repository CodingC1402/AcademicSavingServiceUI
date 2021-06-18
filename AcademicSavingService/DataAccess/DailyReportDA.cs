﻿using System;
using System.Collections.ObjectModel;
using AcademicSavingService.INPC;
using SqlKata.Execution;

namespace AcademicSavingService.DataAccess
{
    public class DailyReportDA : BaseDataAccess<DailyReportINPC, int>
    {
        public void UpdateReportMoney(decimal soTien, int maSo, DateTime ngayTao)
        {
            string q = $"CALL CapNhatTienTrongBaoCao({_SoTienVar}, {_MaSoVar}, {_NgayTaoVar})";
            cmd.CommandText = q;
            cmd.Parameters.Clear();
            cmd.Parameters.AddWithValue(_SoTienVar, soTien);
            cmd.Parameters.AddWithValue(_MaSoVar, maSo);
            cmd.Parameters.AddWithValue(_NgayTaoVar, ngayTao);

            BaseDBConnection.OpenConnection();
            cmd.ExecuteNonQuery();
            BaseDBConnection.CloseConnection();
        }

        public override void Create(DailyReportINPC report)
        {
            string q = $"CALL TongHopBaoCaoNgay({_NgayBaoCaoVar}, {_KyHanBaoCaoVar})";
            cmd.CommandText = q;
            cmd.Parameters.Clear();
            cmd.Parameters.AddWithValue(_NgayBaoCaoVar, report.Ngay);
            cmd.Parameters.AddWithValue(_KyHanBaoCaoVar, report.KyHan);

            BaseDBConnection.OpenConnection();
            cmd.ExecuteNonQuery();
            BaseDBConnection.CloseConnection();
        }

        public override void Delete(int key)
        {
            throw new NotImplementedException();
        }

        public override ObservableCollection<DailyReportINPC> GetAll()
        {
            var collection = db.Query(_tableName).Get<DailyReportINPC>();
            return new ObservableCollection<DailyReportINPC>(collection);
        }

        private const string _NgayBaoCaoVar = "@NgayBaoCao";
        private const string _KyHanBaoCaoVar = "@KyHanBaoCao";
        private const string _SoTienVar = "@SoTien";
        private const string _MaSoVar = "@MaSo";
        private const string _NgayTaoVar = "@NgayTao";

        protected override string _tableName => "BAOCAONGAY";
    }
}