﻿using PropertyChanged;
using System.ComponentModel;
using System.Threading.Tasks;
using System.Collections.ObjectModel;
using MahApps.Metro.IconPacks;
using System.Windows.Media;
using System.Windows;
using ControlzEx.Theming;

namespace AcademicSavingService.ViewModel
{
	[AddINotifyPropertyChangedInterface]
	class MainViewModel : INotifyPropertyChanged
	{
		public event PropertyChangedEventHandler PropertyChanged = (sender, e) => { };
		public ObservableCollection<MenuItemViewModel> MenuItems { get; set; }
		public ObservableCollection<MenuItemViewModel> MenuOptionItems { get; set; }
        public SolidColorBrush TitleBarBackGround { get; set; }

        public static MainViewModel Instance { get; protected set; }
        public bool AskBeforeUpdate { get; set; }
        public bool AskBeforeDelete { get; set; }

        public MainViewModel()
        {
            Instance = this;
            Load();
            CreateMenuItems();
        }

        protected void Load()
		{

		}

        protected void CreateMenuItems()
        {
            TitleBarBackGround = (SolidColorBrush)(Application.Current.FindResource("MahApps.Brushes.AccentBase"));

            MenuItems = new ObservableCollection<MenuItemViewModel>
            {
                new HomeViewModel(this)
                {
                    Icon = new PackIconMaterial() {Kind = PackIconMaterialKind.Home},
                    Label = "Home menu",
                    ToolTip = "Home menu"
                },
                new BanksManagerViewModel(this)
                {
                    Icon = new PackIconMaterial() {Kind = PackIconMaterialKind.Bank},
                    Label = "Banks manager",
                    ToolTip = "Where you manage banks"
                },
                new ServicesManagerViewModel(this)
                {
                    Icon = new PackIconMaterial() {Kind = PackIconMaterialKind.CurrencyEur},
                    Label = "Services manager",
                    ToolTip = "Where you manage services"
                },
                new ReportsManagerViewModel(this)
                {
                    Icon = new PackIconMaterial() {Kind = PackIconMaterialKind.Notebook},
                    Label = "Reports",
                    ToolTip = "where you manage reports"
                }
            };

            MenuOptionItems = new ObservableCollection<MenuItemViewModel>
            {
                new ContactAndHelpViewModel(this)
                {
                    Icon = new PackIconMaterial() {Kind = PackIconMaterialKind.Help },
                    Label = "Helps",
                    ToolTip = "Contact the developers"
                },
                new SettingsViewModel(this)
                {
                    Icon = new PackIconMaterial() {Kind = PackIconMaterialKind.Cog},
                    Label = "Settings",
                    ToolTip = "The App settings"
                }
            };
        }
    }
}
